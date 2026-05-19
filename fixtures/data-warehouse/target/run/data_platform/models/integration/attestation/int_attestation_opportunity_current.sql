
  create or replace   view dw_dev.dev_jkizer.int_attestation_opportunity_current
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$$$, 
  
    "ELATION_ID" COMMENT $$$$, 
  
    "CAREGAP_ID" COMMENT $$$$, 
  
    "DEFINITION_ID" COMMENT $$$$, 
  
    "ATTESTATION_OPPORTUNITY_SKEY" COMMENT $$$$, 
  
    "ATTESTATION_OPPORTUNITY_VERSION_SKEY" COMMENT $$$$, 
  
    "ICD_10_CODE" COMMENT $$$$, 
  
    "STATUS" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

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
  );

