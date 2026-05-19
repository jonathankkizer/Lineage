

with low_literacy_patients as (
    select
        suvida_id,
        patient_id,
        tag_value
    from dw_dev.dev_jkizer.fct_patient_tag
    where
        tag_value in ('Low Literacy', 'Low-literacy') and
        is_active_tag = TRUE
),

-- Strictest interpretation: patient must have latest_is_consented = true for EVERY
-- messaging category they've answered. Any latest-per-category "no" excludes the patient.
-- Reads from dim_patient_consent (PR 6 refactor).
latest_text_consents as (
    select suvida_id
    from dw_dev.dev_jkizer.dim_patient_consent
    where category in (
        'SMS (Text) Communications',
        'Electronic Appointment Notifications',
        'Mobile Phone Communications'
    )
    group by suvida_id
    having booland_agg(latest_is_consented) = true
),

event_logs_with_event_group_id as (
    select
        logs.*,
        events.event_group_id
    from source_prod.sms.patient_emergency_communication_event_logs logs
    left join source_prod.sms.patient_emergency_communication_events events
        on logs.event_id = events.event_id
),

communications as (
    select
        ps.suvida_id,
        ps.elation_id,
        ps.first_name,
        ps.last_name,
        ps.phone,
        phone.phone_type,
        phone.line_type,
        ps.preferred_language,
        iff(llpt.tag_value is null, false, true) as low_literacy,
        iff(ptcs.suvida_id is null, false, true) as sms_opt_in,
        iff(dncr.elation_id is null, false, true) as do_not_contact,
        ps.market_name,
        ps.location_name,
        ps.location_state,
        grps.group_id,
        evnts.event_id,
        evnts.event_group_id,
        evnts.event_name,
        evnts.event_delivery_method,
        tmpl.template_id as message_template_id,
        tmpl.template as message_template
    from dw_dev.dev_jkizer.patient_summary ps
    left join low_literacy_patients llpt
        on ps.suvida_id = llpt.suvida_id and
            ps.elation_id = llpt.patient_id
    left join latest_text_consents ptcs
        on ps.suvida_id = ptcs.suvida_id
    left join source_prod.sms.patient_emergency_communication_groups grps
        on
            case
                when lower(ps.preferred_language) = 'spanish' then 'spanish; castilian'
                when ps.preferred_language is null or ps.preferred_language = '' then 'english'
                else lower(ps.preferred_language)
            end = lower(grps.language)
    left join source_prod.sms.patient_emergency_communication_events evnts
        on grps.group_id = evnts.group_id
    left join event_logs_with_event_group_id lgs
            on evnts.event_group_id = lgs.event_group_id and
            ps.suvida_id = lgs.suvida_id
    left join source_prod.messaging.template tmpl
        on evnts.message_template = tmpl.template_id
    -- Pull and match on any patients that have manually opted out via texting STOP (patient Id + delivery method)
    left join source_prod.messaging.dncr dncr
        on ps.elation_id = dncr.elation_id and
            trim(lower(evnts.event_delivery_method)) = trim(lower(dncr.dncr_type))
    left join source_prod.messaging.phone phone
        on ps.suvida_id = phone.suvida_id and
           ps.phone = phone.phone
    where
        ps.is_active_assignment = 1 and
        lower(ps.elation_status) <> 'deceased' and
        evnts.event_enabled = TRUE and
        lgs.event_id is null
),

comms_with_preferences as (
    select
        to_varchar(comms.value:channel) as comm,
        as_integer(comms.value:rank) as precedence_rank,
        case
            when comms.value:channel = 'SMS' and c.do_not_contact = 1 then 2
            when comms.value:channel = 'SMS' and c.low_literacy = 1 then 2
            when comms.value:channel = 'SMS' and c.sms_opt_in = 0 then 2
            when comms.value:channel = 'SMS' and lower(line_type) <> 'mobile' then 2
            else 1
        end as preference_rank,
        c.*
    from communications c
    cross join table(flatten(input => PARSE_JSON('[{"channel":"SMS","rank":1},{"channel":"Voice","rank":2}]'))) comms
    where
        lower(c.event_delivery_method) = lower(comms.value:channel)
),

ranked_comms as (
    select 
        *,
        row_number() over (partition by suvida_id, event_group_id order by preference_rank, precedence_rank) as _pref_idx
    from comms_with_preferences
)

select *
from ranked_comms
where _pref_idx = 1