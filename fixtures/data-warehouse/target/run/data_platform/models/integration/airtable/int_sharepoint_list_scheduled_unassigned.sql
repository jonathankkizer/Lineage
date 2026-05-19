
  create or replace   view dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$$$, 
  
    "FULL_NAME" COMMENT $$$$, 
  
    "FIRST_NAME" COMMENT $$$$, 
  
    "LAST_NAME" COMMENT $$$$, 
  
    "BIRTH_DATE" COMMENT $$$$, 
  
    "ELATION_PATIENT_URL" COMMENT $$$$, 
  
    "LOCATION_NAME" COMMENT $$$$, 
  
    "PAYER_NAME" COMMENT $$$$, 
  
    "ELATION_INSURANCE_NAME" COMMENT $$$$, 
  
    "ELATION_INSURANCE_PLAN" COMMENT $$$$, 
  
    "ELATION_INSURANCE_MEMBER_ID" COMMENT $$$$, 
  
    "ELIGIBILITY_START_MONTH" COMMENT $$$$, 
  
    "LAST_PCP_APPT_DATE" COMMENT $$$$, 
  
    "NEXT_PCP_APPT_DATE" COMMENT $$$$, 
  
    "CUMULATIVE_PCP_VISITS" COMMENT $$$$, 
  
    "NUM_PCP_VISITS_YTD_GROUP" COMMENT $$$$, 
  
    "HIGH_RISK_PATIENT" COMMENT $$$$, 
  
    "INTEGRATION_SKEY" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

select
    suvida_id,
    full_name,
    first_name,
    last_name,
    birth_date,
    elation_patient_url,
    location_name,
    payer_name,
    elation_insurance_name,
    elation_insurance_plan,
    elation_insurance_member_id,
    eligibility_start_month,
    last_pcp_appt_date,
    next_pcp_appt_date,
    cumulative_pcp_visits,
    num_pcp_visits_ytd_group,
    high_risk_patient,
    integration_skey
from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental
where snapshot_date = (select max(snapshot_date) from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental)
  );

