with temp_vitals as (
	select *,
		regexp_replace(temperature,'([^0-9.])','.') as clean_temperature
	from  elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.vital v
) 
select
	ID as vital_id,
	to_varchar(patient_id) as patient_id,
	practice_id,
	visit_note_id,
	try_to_number(bp_s) as blood_pressure_systolic,
	try_to_number(bp_d) as blood_pressure_diastolic,
	bp_note,
	case 
		when try_to_number(bp_s) < 140 
			and try_to_number(bp_d) < 90 
		then true
		when bp_s is null or bp_d is null
		then null
		else false
	end as is_controlled_blood_pressure,
	try_to_number(height) as height,
	height_units,
	height_note,
	try_to_number(weight) as weight,
	weight_units,
	weight_note,
	bmi as bmi,
	try_to_number(replace(translate(hr, '`+%-', '~~~~'), '~', '')) as heart_rate,
	hr_note as heart_rate_note,
	try_to_number(replace(translate(O2_percent, '+%', '~~'), '~', '')) as oxygen_percent,
	O2_note as oxygen_note,
	try_to_number(pain) as pain,
	pain_note,
	try_to_number(rr) as respiratory_rate,
	rr_note as respiratory_rate_note,
	try_to_number(
		case when clean_temperature like '%.'
		then left(clean_temperature,len(clean_temperature)-1)
		else clean_temperature end
	) as temperature,
	temperature_units,
	to_timestamp(document_date) as document_datetime,
	chart_feed_date as chart_feed_datetime,
	to_timestamp(last_modified) as last_modified_datetime,
	to_timestamp(creation_time) as creation_datetime,
	created_by_user_id,
	to_timestamp(signed_time) as signed_datetime,
	to_timestamp(deletion_time) as deletion_datetime,
	signed_by_user_id,
	'Elation' as _source
from temp_vitals
where deletion_time is null