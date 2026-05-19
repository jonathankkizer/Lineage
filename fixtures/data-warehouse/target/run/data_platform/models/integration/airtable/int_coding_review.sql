
  
    

create or replace transient table dw_dev.dev_jkizer.int_coding_review
    copy grants
    
    
    as (select 
	pa.appointment_skey,
	pa.appointment_status,
	ps.full_name,
	ps.birth_date,
	ps.elation_patient_url,
	ps.payer_name,
	ps.payer_member_id,
	pa.appointment_date,
	pa.appointment_time,
	pa.appointment_provider_name as provider_name,
	pa.appointment_location_name as location_name,
	ps.outstanding_v28_hcc_label as suspect_hccs, 
	hcc_suspect as internal_hcc_suspect,
	suspect.suspect_icd_10_code as internal_suspect_icd_10_code,
	null as provider_accepted_icds,
	null as provider_dismissed_icds,
	ps.outstanding_v28_community_raf as suspected_raf_score,
	mcp.assigned_coder as assigned_coder,
	ps.cumulative_pcp_visits,
	pa.appointment_type_category,
	pa.appointment_type,
	pa.appointment_provider_category,
from dw_dev.dev_jkizer.patient_appointment pa
inner join dw_dev.dev_jkizer.patient_summary ps 
	on ps.suvida_id = pa.suvida_id
left join dw_dev.dev_jkizer_source.map_coder_provider_pre_visit mcp
	on pa.appointment_provider_name = mcp.provider_name
left join dw_dev.dev_jkizer.hcc_suspect_combined suspect 
	on suspect.suvida_id = pa.suvida_id 
	and suspect.hcc_suspect = 'morbid_obesity' -- take out this line when CKD is approved
where pa.appointment_date between dateadd(day, 1, current_date()) and dateadd(day, 7, current_date())
and pa.appointment_status not in ('cancelled')
and pa.is_provider_name_match = true
and ps.is_active_assignment = 1
and pa.appointment_provider_category in ('PCP')
and pa.appointment_type_category not ilike '%acute%'
    )
;


  