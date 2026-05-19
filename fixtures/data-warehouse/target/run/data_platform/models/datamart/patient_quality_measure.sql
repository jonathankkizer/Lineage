
  
    

create or replace transient table dw_dev.dev_jkizer.patient_quality_measure
    copy grants
    
    
    as (with airtable_data as (
	select
		quality_measure_skey,
		workflow_status_detail,
		workflow_note,
		workflow_attachment,
		check_again_date,
		last_modified_by_name,
		last_modified_by_email,
		last_modified_datetime,
		airtable_id,
	from dw_dev.dev_jkizer_staging.stg_airtable_workflow_part_c
	where workflow_status_index = 1 -- most recent status
), prior_year as (
	select
		suvida_id,
		quality_measure,
		measure_status,
		measure_year,
	from dw_dev.dev_jkizer.fct_quality_measure
	where measure_year_report_rank = 1
	and measure_year = dateadd(year, -1, date_trunc(year, current_date()))
	and quality_measure not in ('Plan All-Cause Readmissions', 'TRC - Medication Reconciliation Post-Discharge', 'TRC - Notification of Inpatient Admission', 'TRC - Receipt of Discharge Information', 'TRC - Patient Engagement after Inpatient Discharge', 'Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)')
), awell_quality as (
	select 
		cf.suvida_id, 
        cf.care_flow_id,
        cf.orchestrated_instance_id,
		cf.object_name,
		cf.activity_date,
		date_trunc('year', cf.activity_date) as awell_year,
		case 
			when cf.object_name = 'Outreach - Diabetic Eye Exam' then 'Diabetes Care - Eye Exam'
			when cf.object_name = 'Outreach - A1C Scheduling' then 'Diabetes Care - Blood Sugar Controlled'
			when cf.object_name = 'Outreach - DEXA' then 'Osteoporosis Management Women who had Fx' 
			when cf.object_name = 'Outreach - Breast Cancer Screening' then 'Breast Cancer Screening'
			when cf.object_name = 'Outreach - Colorectal Cancer Screening' then 'Colorectal Cancer Screening'	
			when cf.object_name = 'Outreach - BP Scheduling' then 'Controlling Blood Pressure'			 
			else null 
		end as mapped_quality_track_name,
		max(case when action = 'activate' then cf.activity_date else null end) as awell_started_date,
		max(case when action = 'complete' then cf.activity_date else null end) as awell_completed_date,
        max(case when question_title = 'Was patient outreach successful?' then action_value_label else null end) as is_outreach_successful,
        max(case when question_title = 'Appointment date' then to_date(replace(action_value_raw, '"', '')) else null end) as appointment_date,
		max(case when question_title = 'Notes' then action_value_raw else null end) as awell_notes
	from dw_dev.dev_jkizer.patient_awell_care_flows cf
	left join dw_dev.dev_jkizer.patient_awell_action_responses response
		on response.care_flow_id = cf.care_flow_id 
		and response.suvida_id = cf.suvida_id 
		and response.track_name = cf.object_name
	where cf.object_type = 'track' 
	and cf.care_flow_name = 'Guia Quality Gap Assistance' 
	and date_trunc('year', cf.activity_date) >= '2025-01-01'
    group by all
	-- for some reason, there are several patients that go through the same quality gap care flow more than once. take the most recent care flow
	qualify row_number() over (partition by cf.suvida_id, cf.object_name order by cf.activity_date desc) = 1
)

select
	fqm.quality_measure_report_skey,
	fqm.quality_measure_skey,
	fqm.suvida_id,
	fqm.measure_source,
	fqm.measure_year,
	fqm.quality_measure,
	fqm.measure_weight,
	fqm.quality_measure_type,
	fqm.measure_numerator,
	fqm.measure_numerator as performance_numerator,
	fqm.measure_denominator,
	fqm.measure_status,
	py.measure_status as prior_year_measure_status,
	fqm.measure_detail,
	fqm.payer_group,
	fqm.aco_flag,
	fqm.report_date,
	fqm.src_file_name,
	null as suvida_numerator,
	null as suvida_measure_status,
	null as suvida_measure_date,
	null as evidence_desc,
	fqm.patient_measure_report_rank,
	fqm.patient_report_rank,
	-- fqm.report_rank,
	fqm.measure_year_report_rank,
	-- fqm.quality_measure_rn,
	sysdate() as data_warehouse_refresh,
	awell.awell_started_date,
	awell.awell_completed_date,
	awell.is_outreach_successful,
	awell.appointment_date as awell_appointment_date,
	awell.awell_notes,
	iff(fqm.measure_year_report_rank = 1, true, false) as is_measure_year_current_report,
	-- iff(fqm.report_rank = 1 and fqm.patient_report_rank = 1 and year(fqm.measure_year) = year(current_date()), true, false) as is_current_report,
	iff(fqm.quality_measure_rn = 1, true, false) as is_first_measure_appearance,
	greatest(coalesce(fqm.measure_numerator, 0)) as combined_numerator,
	iff(greatest(coalesce(fqm.measure_numerator, 0)) = 1, 'closed', 'open') as combined_measure_status,
	ad.workflow_status_detail,
	r.workflow_status,
	ad.workflow_note,
	ad.check_again_date as workflow_check_again_date,
	ad.last_modified_by_name as workflow_last_modified_by_name,
	ad.last_modified_by_email as workflow_last_modified_by_email,
	ad.last_modified_datetime as workflow_last_modified_by_datetime,
	ad.airtable_id as workflow_airtable_id,
	quality_engine.gap_status as current_quality_engine_status,
	quality_engine.stage_name as current_quality_engine_stage_name,
	quality_engine.stage as current_quality_engine_stage,
	case
		when lower(quality_engine.gap_status) in ('pending', 'closed') or fqm.measure_numerator = 1
		then 1
		else 0
	end as quality_engine_measure_numerator,
	quality_engine.quality_engine_info_array as current_quality_engine_quality_engine_info_array,
	fqm.compas_flag,
from dw_dev.dev_jkizer.fct_quality_measure fqm
left join airtable_data ad
	on fqm.quality_measure_skey = ad.quality_measure_skey
left join prior_year py
	on fqm.suvida_id = py.suvida_id
	and fqm.quality_measure = py.quality_measure
	and fqm.measure_year = dateadd(year, 1, py.measure_year)
left join dw_dev.dev_jkizer_source.map_quality_workflow_rollup r
	on ad.workflow_status_detail = r.workflow_status_detail
left join awell_quality awell 
	on awell.suvida_id = fqm.suvida_id 
	and awell.mapped_quality_track_name = fqm.quality_measure 
	and awell.awell_year = date(fqm.measure_year)
left join dw_dev.dev_jkizer_quality.quality_process_measures quality_engine
	on fqm.quality_measure = quality_engine.quality_measure
	and fqm.suvida_id = quality_engine.suvida_id
	and year(fqm.measure_year) = quality_engine.measure_year
	and quality_engine.latest_rank_overall  = 1
where fqm.suvida_id is not null
and year(fqm.measure_year) in ((year(current_date())), (year(current_date())-1)) -- grab current and prior year
and quality_report_in_month_rank = 1 -- grabbing latest data available for each month
    )
;


  