
  create or replace   view dw_dev.dev_jkizer.int_sharepoint_list_outreach
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$$$, 
  
    "ELATION_ID" COMMENT $$$$, 
  
    "ELATION_PATIENT_URL" COMMENT $$$$, 
  
    "FULL_NAME" COMMENT $$$$, 
  
    "PHONE" COMMENT $$$$, 
  
    "NUM_PCP_VISITS_YTD" COMMENT $$$$, 
  
    "IS_AWV_COMPLETE_YTD" COMMENT $$$$, 
  
    "LAST_PCP_APPT_DATE" COMMENT $$$$, 
  
    "PREFERRED_LANGUAGE" COMMENT $$$$, 
  
    "LOCATION_NAME" COMMENT $$$$, 
  
    "PROVIDER_NAME" COMMENT $$$$, 
  
    "EMR_CLAIMS_BLENDED_RISK_SCORE_ADJ_ROLLING" COMMENT $$$$, 
  
    "OUTSTANDING_V28_COMMUNITY_RAF" COMMENT $$$$, 
  
    "RECENT_COME_BACK_CARE_NOTE_TEXT" COMMENT $$$$, 
  
    "ELIGIBILITY_START_MONTH" COMMENT $$$$, 
  
    "CUMULATIVE_PCP_VISITS" COMMENT $$$$, 
  
    "HIGH_RISK_PATIENT" COMMENT $$$$, 
  
    "DUAL_STATUS" COMMENT $$$$, 
  
    "PRIORITY" COMMENT $$$$, 
  
    "DAYS_SINCE_LAST_PCP_VISIT" COMMENT $$$$, 
  
    "CATEGORY" COMMENT $$$$, 
  
    "DATE_SORT" COMMENT $$$$, 
  
    "INTEGRATION_SKEY" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

select
    suvida_id,
    elation_id,
    elation_patient_url,
    full_name,
    phone,
    num_pcp_visits_ytd,
    is_awv_complete_ytd,
    last_pcp_appt_date,
    preferred_language,
    location_name,
    provider_name,
    emr_claims_blended_risk_score_adj_rolling,
    outstanding_v28_community_raf,
    recent_come_back_care_note_text,
    eligibility_start_month,
    cumulative_pcp_visits,
    high_risk_patient,
    dual_status,
    priority,
    days_since_last_pcp_visit,
    category,
    date_sort,
    integration_skey
from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental
where snapshot_date = (select max(snapshot_date) from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental)
  );

