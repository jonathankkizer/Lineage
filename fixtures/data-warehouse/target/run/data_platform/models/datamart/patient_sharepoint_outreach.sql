
  
    

create or replace transient table dw_dev.dev_jkizer.patient_sharepoint_outreach
    copy grants
    
    
    as (select
	suvida_id,
	snapshot_date,
	event_type,
	full_name,
	phone,
	dual_status,
	preferred_language,
	elation_id,
	elation_patient_url,
	location_name,
	provider_name,
	category,
	priority,
	last_pcp_appt_date,
	days_since_last_pcp_visit,
	num_pcp_visits_ytd,
	is_awv_complete_ytd,
	cumulative_pcp_visits,
	eligibility_start_month,
	emr_claims_blended_risk_score_adj_rolling,
	outstanding_v28_community_raf,
	high_risk_patient,
	recent_come_back_care_note_text,
	integration_skey,
	attempt,
	attempt_date,
	attempt_result,
	iff(attempt_result ilike '%scheduled%', true, false) as is_successful_attempt,
	staff_attempted_id,
	staff_attempted
from dw_dev.dev_jkizer.fct_sharepoint_outreach_list
    )
;


  