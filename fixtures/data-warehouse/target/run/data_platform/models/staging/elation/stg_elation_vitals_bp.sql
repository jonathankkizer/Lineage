
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_vitals_bp
  
  copy grants
  
  
  as (
    select
	ID as blood_pressure_id,
	vital_id,
	to_varchar(PATIENT_ID) as elation_id,
	practice_id,
	visit_note_id,
	try_to_number(bp_s) as blood_pressure_systolic,
	try_to_number(bp_d) as blood_pressure_diastolic,
	bp_note,
	case 
		when try_to_number(bp_s) < 140 
			and try_to_number(bp_d) < 90 
		then true 
		else false
	end as is_controlled_blood_pressure,
	document_date as document_datetime,
	chart_feed_date as chart_feed_datetime,
	last_modified as last_modified_datetime,
	creation_time as creation_datetime,
	created_by_user_id,
	signed_time as signed_datetime,
	signed_by_user_id
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.vital_bp
  );

