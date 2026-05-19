with base as (
    select
        elation_id,
        icd_10_code,
        doc_tag as doctag,
        date_actioned as event_at
    from source_prod.attestation.attestation_action_event_log
)

select
    *,
    case
        when doctag ilike 'confirm%' then 'physician_confirm'
        when doctag ilike 'disconfirm%' then 'physician_disconfirm'
        else 'physician_other'
    end as event_action
from base