

select
    suvida_id,
    elation_id,
    sec.caregap_id,
    sec.definition_id,
    attestation_opportunity_skey,
    attestation_opportunity_version_skey,
    icd_10_code,
    sec.status
from dw_dev.dev_jkizer_staging.stg_attestation_event_log sael
left join dw_dev.dev_jkizer_staging.stg_elation_health_care_gap sec
    on sael.caregap_id = sec.caregap_id
where sec.status = 'open'