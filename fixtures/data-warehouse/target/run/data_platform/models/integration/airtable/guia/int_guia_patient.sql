
  create or replace   view dw_dev.dev_jkizer.int_guia_patient
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$$$, 
  
    "FULL_NAME" COMMENT $$$$, 
  
    "BIRTH_DATE" COMMENT $$$$, 
  
    "ELATION_PATIENT_URL" COMMENT $$$$, 
  
    "ELATION_ID" COMMENT $$$$, 
  
    "PROVIDER_NAME" COMMENT $$$$, 
  
    "LOCATION_NAME" COMMENT $$$$, 
  
    "LAST_PCP_APPT_DATE" COMMENT $$$$, 
  
    "NEXT_PCP_APPT_DATE" COMMENT $$$$, 
  
    "NEXT_CARETEAM_APPT_DATE" COMMENT $$$$, 
  
    "PCP_APPT_NO_SHOW_RATE_ROLLING_12" COMMENT $$$$, 
  
    "GUIA_APPT_NO_SHOW_RATE_ROLLING_12" COMMENT $$$$, 
  
    "HIGH_RISK_PATIENT" COMMENT $$$$, 
  
    "EMAIL" COMMENT $$$$, 
  
    "PHONE" COMMENT $$$$, 
  
    "PHONE_TYPE" COMMENT $$$$, 
  
    "SECONDARY_PHONE" COMMENT $$$$, 
  
    "SECONDARY_PHONE_TYPE" COMMENT $$$$, 
  
    "ADDRESS_LINE_1" COMMENT $$$$, 
  
    "ADDRESS_LINE_2" COMMENT $$$$, 
  
    "CITY" COMMENT $$$$, 
  
    "STATE" COMMENT $$$$, 
  
    "ZIP" COMMENT $$$$, 
  
    "IS_ACTIVE_PATIENT" COMMENT $$$$, 
  
    "IS_ACTIVE_ASSIGNMENT" COMMENT $$$$, 
  
    "PAYER_PARENT" COMMENT $$$$, 
  
    "PAYER_NAME" COMMENT $$$$, 
  
    "PAYER_CONTRACT" COMMENT $$$$, 
  
    "PAYER_PLAN_NAME" COMMENT $$$$, 
  
    "PAYER_MEMBER_ID" COMMENT $$$$, 
  
    "DUAL_STATUS" COMMENT $$$$, 
  
    "PREFERRED_LANGUAGE" COMMENT $$$$, 
  
    "ELIGIBILITY_START_MONTH" COMMENT $$$$, 
  
    "ELIGIBILITY_MAX_MONTH" COMMENT $$$$, 
  
    "SDOH_MOST_RECENT_COMPLETION_DATE" COMMENT $$$$, 
  
    "SDOH_FORM_DUE_DATE" COMMENT $$$$, 
  
    "SDOH_FORM_DUE_IND" COMMENT $$$$, 
  
    "ROI_MOST_RECENT_COMPLETION_DATE" COMMENT $$$$, 
  
    "ROI_FORM_DUE_DATE" COMMENT $$$$, 
  
    "FALLS_INSECURITY" COMMENT $$$$, 
  
    "HOUSING_INSECURITY" COMMENT $$$$, 
  
    "FINANCIAL_INSECURITY" COMMENT $$$$, 
  
    "FOOD_INSECURITY" COMMENT $$$$, 
  
    "TRANSPORTATION_INSECURITY" COMMENT $$$$, 
  
    "ACTIVE_INSECURITIES" COMMENT $$$$, 
  
    "FAP_COMPLETION_DATE" COMMENT $$$$, 
  
    "IS_FAP_ENROLLED" COMMENT $$$$, 
  
    "ADVANCE_CARE_PLAN_DOCUMENT_ATTACHED" COMMENT $$$$, 
  
    "ADVANCE_CARE_PLAN_DOCUMENT_ATTACHED_DATE" COMMENT $$$$, 
  
    "GUIA_PATIENT_INTEGRATION_SKEY" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

select
	suvida_id, -- unique key
	full_name,
	birth_date,
	elation_patient_url,
	elation_id,
	provider_name,
	elation_location_name as location_name,
	last_pcp_appt_date,
	next_pcp_appt_date,
	next_careteam_appt_date,
	pcp_appt_no_show_rate_rolling_12,
	guia_appt_no_show_rate_rolling_12,
	iff(high_risk_patient = 1, 'High Risk', null) as high_risk_patient,
	email,
	phone,
	phone_type,
	secondary_phone,
	secondary_phone_type,
	address_line_1,
	address_line_2,
	city,
	state,
	zip,
	iff(is_active_patient = 1, 'Active', 'Inactive') as is_active_patient,
	iff(is_active_assignment = 1, 'Active Assignment', 'Inactive Assignment') as is_active_assignment,
	payer_parent,
	payer_name,
	payer_contract,
	payer_plan_name,
	payer_member_id,
	dual_status,
	preferred_language,
	eligibility_start_month,
	eligibility_max_month,
	sdoh_most_recent_completion_date,
	sdoh_form_due_date,
	sdoh_form_due_ind,
	roi_most_recent_completion_date,
	roi_form_due_date,
	falls_insecurity,
	housing_insecurity,
	financial_insecurity,
	food_insecurity,
	transportation_insecurity,
	active_insecurities,
	fap_completion_date,
	is_fap_enrolled,
	advance_care_plan_document_attached,
	date(advance_care_plan_document_attached_datetime) as advance_care_plan_document_attached_date,
	md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(is_active_patient as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dual_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sdoh_most_recent_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sdoh_form_due_ind as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sdoh_form_due_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(roi_most_recent_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elation_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fap_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(preferred_language as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(advance_care_plan_document_attached as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as guia_patient_integration_skey,
from dw_dev.dev_jkizer.patient_summary
  );

