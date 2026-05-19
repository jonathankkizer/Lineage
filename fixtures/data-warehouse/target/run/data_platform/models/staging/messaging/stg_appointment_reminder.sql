
  create or replace   view dw_dev.dev_jkizer_staging.stg_appointment_reminder
  
  copy grants
  
  
  as (
    

with service_locations as (
    select sl.*, esl.service_location_name
    from dw_dev.dev_jkizer_staging.service_locations sl
    left join dw_dev.dev_jkizer_staging.stg_elation_service_location esl
        on sl.elation_id = esl.service_location_id

    union all

    select vl.*, esl.service_location_name
    from source_prod.geocoding.virtual_locations vl
    left join dw_dev.dev_jkizer_staging.stg_elation_service_location esl
        on vl.elation_id = esl.service_location_id  
),

datetimes as (
    select
        appt.patient_id,
        appointment_id,
        case
            when sl.state = 'AZ' then convert_timezone('UTC', 'America/Phoenix', to_timestamp_ntz(appointment_date))
            when sl.state = 'TX' then convert_timezone('UTC', 'America/Chicago', to_timestamp_ntz(appointment_date))
            when cities.state_code = 'AZ' then convert_timezone('UTC', 'America/Phoenix', to_timestamp_ntz(appointment_date))
            when cities.state_code = 'TX' then convert_timezone('UTC', 'America/Chicago', to_timestamp_ntz(appointment_date))
            else to_timestamp_ntz(appointment_date)
        end as appointment_datetime,
        to_timestamp_ntz(appointment_date) as appointment_datetime_utc
    from source_prod.misc.appointment_staging appt
    left join service_locations sl
        on appt.location_id = to_varchar(sl.elation_id)
    left join dw_dev.dev_jkizer.dim_patient pt
        on appt.patient_id = pt.elation_id
    left join source_prod.misc.src_misc_cities cities 
        on trim(pt.city) = lower(cities.city_name)
),

datetime_days as (
    select
        *,
        decode(
            DAYNAME(to_timestamp_ntz(dt.appointment_datetime)),
            'Mon', 'Monday',
            'Tue', 'Tuesday',
            'Tues','Tuesday',
            'Wed', 'Wednesday',
            'Thu', 'Thursday',
            'Thur', 'Thursday',
            'Fri', 'Friday',
            'Sat', 'Saturday',
            'Sun', 'Sunday'
        ) as appointment_day
    from datetimes dt
),

spanish_datetime_days as (
    select
        *,
        decode(
            DAYNAME(to_timestamp_ntz(dt.appointment_datetime)),
            'Mon', 'Lunes',
            'Tue', 'Martes',
            'Tues','Martes',
            'Wed', 'Miércoles',
            'Thu', 'Jueves',
            'Thur', 'Jueves',
            'Fri', 'Viernes',
            'Sat', 'Sábado',
            'Sun', 'Domingo'
        ) as appointment_day
    from datetimes dt
),

spanish_month_names as (
    select
        *,
        decode(
            to_varchar(dt.appointment_datetime, 'MMMM'),
            'January', 'Enero',
            'February', 'Febrero',
            'March','Marzo',
            'April', 'Abril',
            'May', 'Puede',
            'June', 'Junio',
            'July', 'Julio',
            'August', 'Agosto',
            'September', 'Septiembre',
            'October', 'Octubre',
            'November', 'Noviembre',
            'December', 'Diciembre'
        ) as appointment_month
    from datetimes dt
),

low_literacy_patients as (
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
-- NOTE: staging models traditionally shouldn't depend on dim/fct, but this is a pre-existing
-- layering violation (the old code referenced fct_consent here). Worth fixing in a follow-up.
latest_text_consents as (
    select suvida_id
    from dw_dev.dev_jkizer.dim_patient_consent
    where category in (
        'SMS (Text) Communications',
        'Electronic Appointment Notifications',
        'Mobile Phone Communications',
        'Electronic Communications'
    )
    group by suvida_id
    having booland_agg(latest_is_consented) = true
),

appointments as (
    select
        pt.suvida_id,
        pt.elation_id,
        pt.first_name,
        pt.last_name,
        concat(first_name, ' ', last_name) as full_name,
        pt.phone,
        pt.preferred_language,
        iff(llpt.tag_value is null, false, true) as low_literacy,
        iff(ptcs.suvida_id is null, false, true) as sms_opt_in,
        appt.appointment_id,
        dt.appointment_datetime,
        dt.appointment_datetime_utc,
        dt.appointment_day,
        sdt.appointment_day as appointment_day_spanish,
        dt.appointment_day || ', ' || to_varchar(dt.appointment_datetime, 'MMMM DD') || ' at ' || ltrim(to_varchar(dt.appointment_datetime, 'HH12:MI AM'), '0')  as appointment_datetime_formatted,
        dt.appointment_day || ', ' || to_varchar(dt.appointment_datetime, 'MMMM DD') as appointment_date_formatted,
        sdt.appointment_day || ' ' || to_varchar(dt.appointment_datetime, 'DD') || ' de ' || smn.appointment_month || ' a las ' || ltrim(to_varchar(dt.appointment_datetime, 'HH12:MI AM'), '0') as appointment_datetime_spanish_formatted,
        sdt.appointment_day || ' ' || to_varchar(dt.appointment_datetime, 'DD') || ' de ' || smn.appointment_month as appointment_date_spanish_formatted,
        reason,
        appt.status,
        appt.department,
        appt.visit_mode,
        location_id,
        sl.service_location_name as location_name,
        sl.street_1 as location_address,
        sl.city as location_city,
        sl.state as location_state,
        sl.zip as location_zip,
        sl.street_1 || ' ' || sl.city || ', ' || sl.state || ' ' || sl.zip as location_full_address,
        appt.provider_id,
        usr.user_first_name as provider_first_name,
        usr.user_last_name as provider_last_name,
        usr.credentials as provider_credentials,
        usr.user_first_name || ' ' || usr.user_last_name as provider_full_name,
        usr.user_first_name || ' ' || usr.user_last_name || ', ' || usr.credentials as provider_full_name_with_credentials,
        coalesce(regexp_substr(instructions, 'https:\/\/[^,;!:\\s]+'), '') as virtual_link,
        groups.group_id,
        groups.visit_location
    from source_prod.misc.appointment_staging appt
    left join datetime_days dt
        on appt.appointment_id = dt.appointment_id
    left join spanish_datetime_days sdt
        on appt.appointment_id = sdt.appointment_id
    left join spanish_month_names smn
        on appt.appointment_id = smn.appointment_id
    left join dw_dev.dev_jkizer.dim_patient pt
        on appt.patient_id = pt.elation_id
    left join dw_dev.dev_jkizer_staging.stg_elation_user usr
        on appt.provider_id = usr.physician_id
    left join service_locations sl
        on appt.location_id = to_varchar(sl.elation_id)
    inner join source_prod.sms.patient_appointment_reminders_groups groups
        on appt.department = groups.department and
           trim(lower(iff(pt.preferred_language = 'Spanish', pt.preferred_language, 'English'))) = trim(lower(groups.language)) and
           (
                lower(trim(groups.visit_type)) = lower(trim(appt.reason)) or
                (
                    groups.visit_type = '*' and
                    array_contains(upper(trim(appt.visit_mode))::VARIANT, groups.visit_mode)
                )
            )
    left join low_literacy_patients llpt
        on pt.suvida_id = llpt.suvida_id and
           pt.elation_id = llpt.patient_id
    left join latest_text_consents ptcs
        on pt.suvida_id = ptcs.suvida_id
    where
        appt.provider_id not in ('555027024707586') and
        (
            lower(trim(groups.visit_type)) = lower(trim(appt.reason)) or 
            (
                groups.visit_type = '*' and
                array_contains(upper(trim(appt.visit_mode))::VARIANT, groups.visit_mode) and not exists
                (
                    select 1
                    from source_prod.sms.patient_appointment_reminders_groups grps
                    where lower(trim(appt.reason)) = lower(trim(grps.visit_type))
                )
            )
        )
),

-- ==============================================================================
-- EXPERIMENTAL ⬇️
-- ==============================================================================

reminders_with_type as (
    select
        to_varchar(comms.value:channel) as comm,
        as_integer(comms.value:rank) as precedence_rank,
        case
            -- Force SMS to the top for same-day virtual (at home) reminders 
            when comms.value:channel = 'SMS' and to_date(sysdate()) = to_date(appts.appointment_datetime_utc) and appts.visit_location = 'VIRTUAL' then 1
            when comms.value:channel = 'Voice' and to_date(sysdate()) = to_date(appts.appointment_datetime_utc) and appts.visit_location = 'VIRTUAL' then 2
            when comms.value:channel = 'SMS' and appts.low_literacy = 1 then 2
            when comms.value:channel = 'SMS' and appts.sms_opt_in = 0 then 2
            else 1
        end as preference_rank,
        appts.*
    from appointments appts
    cross join table(flatten(input => PARSE_JSON('[{"channel":"SMS","rank":1},{"channel":"Voice","rank":2}]'))) comms
),

event_logs_with_event_group_id as (
    select
        logs.*,
        events.event_group_id
    from source_prod.sms.patient_appointment_reminders_event_logs logs
    left join source_prod.sms.patient_appointment_reminders_events events
        on logs.event_id = events.event_id
),

reminders as (
    select
        iff(dncr.elation_id is not null, TRUE, FALSE) as DNCR,
        appts.*,
        dateadd(
            second,
            case
                when appts.appointment_day = 'Tuesday' and evnts.event_delay = 172800 then -(evnts.event_delay + 100800)
                when appts.appointment_day = 'Monday' and evnts.event_delay = 86400 then -(evnts.event_delay + 100800)
                when appts.appointment_day = 'Monday' then -(evnts.event_delay + 86400)
                else -(evnts.event_delay)
            end,
            appts.appointment_datetime_utc
        ) as scheduled_send_datetime_utc,
        dateadd(
            second,
            case
                when appts.appointment_day = 'Monday' and evnts.event_threshold = 86400 then -(evnts.event_threshold + 86400)
                else -(evnts.event_threshold)
            end,
            appts.appointment_datetime_utc
        ) as cutoff_send_datetime_utc,
        evnts.event_id,
        evnts.event_group_id,
        evnts.event_name,
        evnts.event_order,
        evnts.event_delay,
        evnts.event_threshold,
        evnts.event_type,
        evnts.event_delivery_method,
        lgs.date_created as log_date_created,
        tmplt.template_id as message_template_id,
        tmplt.template as message_template
    from reminders_with_type appts
    -- Match on an event by group, event type, whether the event is enabled, and the delivery method
    -- Filter out any that do not match all criteria
    inner join source_prod.sms.patient_appointment_reminders_events evnts
        on appts.group_id = evnts.group_id and
           evnts.event_enabled = TRUE and
           evnts.event_type = 'Concurrent' and
           trim(lower(evnts.event_delivery_method)) = trim(lower(appts.comm))
    -- Pull and match any previously logged events for the current appointment and event
    left join event_logs_with_event_group_id lgs
        on evnts.event_group_id = lgs.event_group_id and
           appts.appointment_id = lgs.appointment_id and
           appts.appointment_datetime_utc = lgs.appointment_datetime_utc
    -- Pull the matching message template according to the event
    left join source_prod.messaging.template tmplt
        on evnts.message_template = tmplt.template_id
    -- Pull and match on any patients that have manually opted out via texting STOP (patient Id + delivery method)
    left join source_prod.messaging.dncr dncr
        on appts.elation_id = to_varchar(dncr.elation_id) and
           trim(lower(evnts.event_delivery_method)) = trim(lower(dncr.dncr_type))
    where
        -- Filter any rows with no matching group
        appts.group_id is not null and
        -- Filter any rows with a matching and previously logged event
        lgs.event_id is null and
        -- Filter any rows with a matching DNCR entry
        dncr.elation_id is null

),

ranked_reminders as (
    select
        rm.*,        
        rank() over (partition by rm.suvida_id, rm.appointment_id, rm.group_id, rm.event_group_id order by rm.event_order) as _idx,
        row_number() over (partition by rm.suvida_id, rm.appointment_id, rm.group_id, lower(trim(rm.event_name)) order by rm.preference_rank, rm.precedence_rank) as _pref_idx
    from reminders rm
    where
        rm.log_date_created is null and
        sysdate() >= rm.scheduled_send_datetime_utc and
        sysdate() <= rm.cutoff_send_datetime_utc
)

select
    rm.*
from ranked_reminders rm
where
    rm._idx = 1 and
    rm._pref_idx = 1
  );

