with workflow_data as (
	select
		quality_measure_skey,
		"WORKFLOW STATUS DETAIL"::varchar as workflow_status_detail,
		"WORKFLOW NOTES"::varchar as workflow_note,
		"WORKFLOW ATTACHMENTS"::varchar as workflow_attachment,
		"CHECK AGAIN DATE"::varchar as check_again_date,
		"LAST MODIFIED BY":"name"::string as last_modified_by_name,
		"LAST MODIFIED BY":"email"::string as last_modified_by_email,
		"OSTEO - FRACTURE DATE"::varchar as osteo_fracture_date,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		to_timestamp(run_datetime) as run_datetime,
		airtable_id,
	from source_prod.airtable.src_airtable_quality_workflow_status

	union all

	select
		quality_measure_skey,
		"WORKFLOW STATUS DETAIL"::varchar as workflow_status_detail,
		"WORKFLOW NOTES"::varchar as workflow_note,
		"WORKFLOW ATTACHMENTS"::varchar as workflow_attachment,
		"CHECK AGAIN DATE"::varchar as check_again_date,
		"LAST MODIFIED BY":"name"::string as last_modified_by_name,
		"LAST MODIFIED BY":"email"::string as last_modified_by_email,
		"OSTEO - FRACTURE DATE"::varchar as osteo_fracture_date,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		to_timestamp(run_datetime) as run_datetime,
		airtable_id,
	from source_prod.airtable.src_airtable_quality_workflow_status_2025_1
	-- on 2025-10-21, moved data to this table due to an outage/recovery process; above table has data until this date

	union all

	select
		quality_measure_skey,
		"WORKFLOW STATUS DETAIL"::varchar as workflow_status_detail,
		"WORKFLOW NOTES"::varchar as workflow_note,
		"WORKFLOW ATTACHMENTS"::varchar as workflow_attachment,
		"CHECK AGAIN DATE"::varchar as check_again_date,
		"LAST MODIFIED BY":"name"::string as last_modified_by_name,
		"LAST MODIFIED BY":"email"::string as last_modified_by_email,
		"OSTEO - FRACTURE DATE"::varchar as osteo_fracture_date,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		to_timestamp(run_datetime) as run_datetime,
		airtable_id,
	from source_prod.airtable.src_airtable_quality_workflow_status_2026_1 -- initial 2026 data; prior to JSON migration

	union all

	select
		quality_measure_skey,
		parse_json(workflow_fields):"Workflow Status Detail"::string as workflow_status_detail,
		parse_json(workflow_fields):"Workflow Notes"::string as workflow_note,
		parse_json(workflow_fields):"Workflow Attachments"::string as workflow_attachment,
		parse_json(workflow_fields):"Check Again Date"::string as check_again_date,
		parse_json(workflow_fields):"Last Modified By":"name"::string as last_modified_by_name,
		parse_json(workflow_fields):"Last Modified By":"email"::string as last_modified_by_email,
		parse_json(workflow_fields):"Osteo - Fracture Date"::string as osteo_fracture_date,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		to_timestamp(run_datetime) as run_datetime,
		airtable_id,
	from source_prod.airtable.src_airtable_quality_workflow_status_json
)
select
	*,
	last_modified_by_email in ('jkizer@suvidahealthcare.com', 'automations@noreply.airtable.com') as is_automated_activity,
	row_number() over (partition by quality_measure_skey order by last_modified_datetime desc) as workflow_status_index,
from workflow_data