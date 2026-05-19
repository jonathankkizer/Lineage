
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_med_adherence_pharm
  
  copy grants
  
  
  as (
    select
	quality_measure_skey,
	airtable_id,
	"LAST MODIFIED BY":"name"::string as last_modified_by_name,
	"LAST MODIFIED BY":"email"::string as last_modified_by_email,
	convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
	convert_timezone('UTC', 'America/Chicago', to_timestamp("CREATED")) as created_datetime,
	run_datetime,
	"BENZO (MED)" as benzo_med,
	"ACH (MED):" as ach_med,
	"OPIOID (MED)" as opioid_med,
	row_number() over (partition by quality_measure_skey order by "LAST MODIFIED" desc) as workflow_status_index,
from source_prod.airtable.src_airtable_quality_med_adherence_pharm_measures
where lower("LAST MODIFIED BY":"email"::string) not in ('jkizer@suvidahealthcare.com', 'automations@noreply.airtable.com') -- filter out items that this account touched, as updates/loads are done from here and don't count towards work completed
  );

