with base as (
    select
        suvida_id,
        elation_id,
        attestation_opportunity_skey,
        icd_10_code,
        action,
        date_actioned as event_at
    from dw_dev.dev_jkizer_staging.stg_attestation_event_log
)

select
    *,
    case
        when action = 'Create' then 'opportunity_created'
        when action = 'Close' then 'opportunity_closed'
        else lower(action)
    end as event_action
from base