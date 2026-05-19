with airtable_manual_data as (
	select
		airtable_id,
		"LAST MODIFIED BY":"name"::string as last_modified_by_name,
		"LAST MODIFIED BY":"email"::string as last_modified_by_email,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
		convert_timezone('UTC', 'America/Chicago', to_timestamp("CREATED")) as created_datetime,
		run_datetime,
		split("PATIENT ELATION CHART URL", '/')[4]::varchar as source_member_id, -- elation ID
		"PATIENT ELATION CHART URL" as elation_chart_url,
		to_date("ADMISSION DATE:") as admit_date,
		to_date("DISCHARGE DATE") as discharge_date,
		"IS PATIENT STILL ADMITTED? - CHECK IF STILL ADMITTED" as is_patient_still_admitted,
		lower("ADMISSION TYPE") as admit_type,
		"ADMISSION FACILITY" as admit_facility,
		'Airtable' as source,
		'Airtable Manual Entry' as source_type,
	from source_prod.airtable.src_airtable_census_operations_manual_form
	where "PATIENT ELATION CHART URL" is not null
	and split("PATIENT ELATION CHART URL", '/')[4]::varchar != ''
)
select 
	* exclude (admit_type),
	case 
		when admit_type = 'inpatient' then 'inpatient'
		when admit_type = 'er' then 'emergency'
		when admit_type = 'obs' then 'observation'
	end as level_of_care,
from airtable_manual_data
qualify row_number() over (partition by source_member_id, admit_date, discharge_date, admit_type, admit_facility order by last_modified_datetime desc) = 1