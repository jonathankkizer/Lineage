
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_med_adherence
  
  copy grants
  
  
  as (
    with columnar_data as (
	select
		med_adherence_measure_skey,
		airtable_id,
		"LAST MODIFIED BY":"name"::string as last_modified_by_name,
		"LAST MODIFIED BY":"email"::string as last_modified_by_email,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("CREATED")) as created_datetime,
		to_timestamp(run_datetime) as run_datetime,
		"MS ACTION" as ms_action,
		opportunity as opportunity,
		"BARRIER(S)" as barriers,
		interventions,
		"MS NOTES" as ms_notes,
		"ELATION NOTE" as elation_note,
		"NEXT FOLLOW UP DATE" as next_follow_up_date,
		trim("STAGE OF MEDADH OUTREACH") as stage_med_adh_outreach,
		"PERSONAL NOTES" as personal_notes,
		"MEDICATION SPECIALIST" as medication_specialist,
		"COST BARRIER / LIS ADDRESSED" as cost_barrier_lis_addressed,
		"90/100 DAY ADDRESSED" as ds_90_100_day_addressed,
		"TRANSPORTATION ADDRESSED" as transportation_addressed,
		"PCP ACTION ADDRESSED" as pcp_action_addressed,
		"CENTER SUPPORT ADDRESSED" as center_support_addressed,
		"PHARMACY ISSUE ADDRESSED" as pharmacy_issue_addressed,
		"REAL-TIME GDR" as real_time_gdr,
		"ACTION PLAN FOR 2026" as action_plan_for_2026,
	from source_prod.airtable.src_airtable_quality_med_adherence
),

json_data as (
	select
		med_adherence_measure_skey,
		airtable_id,
		parse_json(workflow_fields) as wf,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		to_timestamp(run_datetime) as run_datetime,
	from source_prod.airtable.src_airtable_quality_med_adherence_json
),

json_parsed as (
	select
		med_adherence_measure_skey,
		airtable_id,
		wf:"Last Modified By":"name"::string as last_modified_by_name,
		wf:"Last Modified By":"email"::string as last_modified_by_email,
		last_modified_datetime,
		convert_timezone('UTC', 'America/Chicago', to_timestamp(wf:"Created"::string)) as created_datetime,
		run_datetime,
		wf:"MS Action"::string as ms_action,
		wf:"Opportunity"::string as opportunity,
		wf:"Barrier(s)"::string as barriers,
		wf:"Interventions"::string as interventions,
		wf:"MS Notes"::string as ms_notes,
		wf:"Elation Note "::string as elation_note,
		wf:"Next Follow up Date: "::string as next_follow_up_date,
		trim(wf:"Stage of MedAdh Outreach"::string) as stage_med_adh_outreach,
		wf:"Personal Notes"::string as personal_notes,
		wf:"Medication Specialist"::string as medication_specialist,
		wf:"Cost Barrier / LIS Addressed"::string as cost_barrier_lis_addressed,
		wf:"90/100 Day Addressed"::string as ds_90_100_day_addressed,
		wf:"Transportation Addressed"::string as transportation_addressed,
		wf:"PCP Action Addressed"::string as pcp_action_addressed,
		wf:"Center Support Addressed"::string as center_support_addressed,
		wf:"Pharmacy Issue Addressed"::string as pharmacy_issue_addressed,
		wf:"Real-Time GDR" as real_time_gdr,
		wf:"Action Plan for 2026"::string as action_plan_for_2026,
	from json_data
),

workflow_data as (
	select * from columnar_data
	union all
	select * from json_parsed
)

select
	*,
	lower(last_modified_by_email) in ('jkizer@suvidahealthcare.com', 'automations@noreply.airtable.com') as is_automated_activity,
	row_number() over (partition by med_adherence_measure_skey order by last_modified_datetime desc) as workflow_status_index,
from workflow_data
  );

