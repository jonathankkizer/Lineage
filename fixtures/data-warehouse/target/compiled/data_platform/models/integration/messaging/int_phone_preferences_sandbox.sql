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

-- Most-recent consent event per patient across the 4 messaging categories.
-- Reads from dim_patient_consent (PR 6 refactor) — semantics preserved: the latest event
-- across categories wins, even if that event is a "no" (which excludes the patient below).
latest_text_consent_event as (
    select
        suvida_id,
        latest_response_id,
        latest_consent_at,
        latest_is_consented
    from dw_dev.dev_jkizer.dim_patient_consent
    where category in (
        'SMS (Text) Communications',
        'Electronic Appointment Notifications',
        'Mobile Phone Communications',
        'Electronic Communications'
    )
    qualify row_number() over (partition by suvida_id order by latest_consent_at desc) = 1
),

latest_text_consents as (
    select
        suvida_id,
        'Zentake'             as source,
        latest_response_id    as source_key,
        latest_consent_at     as completed_at_datetime
    from latest_text_consent_event
    where latest_is_consented = true
),

line_intelligence as (
    select
        *,
        row_number() over (partition by suvida_id, phone order by date_created desc) as intel_index
    from source_prod.messaging.phone
),

latest_dncr as (
    select
        elation_id,
        dncr_type,
        date_created
    from source_prod.messaging.dncr
    qualify row_number() over (partition by elation_id, dncr_type order by date_created desc) = 1
)

select distinct
    md5(cast(coalesce(cast(ps.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as suvida_id,
    ps.elation_id,
    ps.phone,
    ptir.phone_type,
    li.line_type,
    iff(llpt.tag_value is null, FALSE, TRUE) as low_literacy,
    iff(ptcs.suvida_id is null, FALSE, TRUE) as sms_opt_in,
    ptcs.source as sms_opt_in_source,
    ptcs.source_key as sms_opt_in_source_key,
    ptcs.completed_at_datetime as sms_opt_in_timestamp,
    iff(dncr.elation_id is not null, TRUE, FALSE) as sms_opt_out,
    dncr.date_created as sms_opt_out_timestamp,
    ps.come_back_to_care_priority,
    ps.num_pcp_visits_ytd
from dw_dev.dev_jkizer.phone_type_intelligence_roster ptir
right join dw_dev.dev_jkizer.int_patient_summary_sandbox ps
    on ps.suvida_id = md5(cast(coalesce(cast(ptir.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) and
       ps.phone = ptir.phone
left join latest_dncr dncr
    on ps.elation_id = to_varchar(dncr.elation_id) and
       dncr.dncr_type = 'SMS'
left join line_intelligence li
    on ps.suvida_id = md5(cast(coalesce(cast(li.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) and
       ps.phone = li.phone and
       li.intel_index = 1
left join low_literacy_patients llpt
    on ps.suvida_id = md5(cast(coalesce(cast(llpt.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) and
       ps.elation_id = llpt.patient_id
left join latest_text_consents ptcs
    on ps.suvida_id = md5(cast(coalesce(cast(ptcs.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
where
    ps.suvida_id is not null