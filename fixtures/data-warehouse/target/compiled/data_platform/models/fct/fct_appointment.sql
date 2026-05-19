select
	md5(cast(coalesce(cast(sea.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.practice_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.appointment_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.physician_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.appointment_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.elation_location_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as appointment_skey,
	md5(cast(coalesce(cast(sea.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.appointment_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sea.physician_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as appointment_encounter_skey,
	suvida_id,
	sea.elation_id,
	sea.appointment_id,
	sea.appointment_date,
	sea.appointment_time,
	sea.appointment_time_utc,
	sea.appointment_datetime,
	sea.appointment_datetime_utc,
	sea.physician_id as user_id,
	seu.physician_id as physician_id,
	coalesce(dp.provider_name, seu.user_name) as appointment_provider_name,
	coalesce(dp.user_first_name, seu.user_first_name) as appointment_provider_first_name,
	coalesce(dp.user_last_name, seu.user_last_name) as appointment_provider_last_name,
	seu2.user_email as appointment_creator_email,
	seu2.user_first_name as appointment_creator_first_name,
	seu2.user_last_name as appointment_creator_last_name,
	atg.appointment_type_category,
	atg.appointment_provider_category,
	atg.visit_level,
	atg.visit_location_type,
	sea.appointment_type,
	sea.appointment_description,
	sea.appointment_instructions,
	sea.appointment_duration,
	eas.appointment_status,
	iff(
		appointment_status in ('checkedOut', 'checkedIn', 'withDr', 'billed', 'vitalsTaken', 'inRoom'),
		1,
		0
	) as appointment_completed_ind,
	sea.created_by_user_id,
	sea.creation_date,
	sea.creation_datetime,
	sea.deletion_datetime,
	sea.last_modified_date,
	sea.last_modified_datetime,
	dl.location_name as appointment_location_name,
	iff(atg.appointment_provider_category = 'PCP', true, false) as is_pcp_appt,
	iff(atg.appointment_provider_category = 'Guia', true, false) as is_guia_appt,
	iff(atg.appointment_provider_category = 'Mental Health', true, false) as is_mh_appt,
	iff(atg.appointment_provider_category = 'Nutrition', true, false) as is_nutrition_appt,
	iff(atg.appointment_provider_category = 'Pharmacy', true, false) as is_pharmacy_appt,
	iff(atg.appointment_provider_category = 'Physical Therapy', true, false) as is_pt_appt,
	iff(coalesce(dp.provider_name, seu.user_name) ilike '%Procedure MA%', true, false) as is_ma_appt,
	iff(atg.visit_method = 'Virtual', true, false) as is_virtual_appt,
	iff(mcc.appointment_type is not null, true, false) as is_class,
	dp.user_id is not null as is_provider_name_match,
from dw_dev.dev_jkizer_staging.stg_elation_appointment sea
left join dw_dev.dev_jkizer_staging.stg_elation_appointment_status eas
	on sea.appointment_id = eas.appointment_id
	and eas._idx = 1
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on sea.elation_id = siw.member_id
	and siw.source = 'Elation'
inner join dw_dev.dev_jkizer_staging.stg_elation_user seu
	on sea.physician_id = seu.user_id
left join dw_dev.dev_jkizer.dim_provider dp
    on seu.user_id = dp.user_id
    and dp.is_actively_seeing_patients = true
left join dw_dev.dev_jkizer_staging.stg_elation_user seu2
	on sea.created_by_user_id = seu2.user_id
left join dw_dev.dev_jkizer_source.map_appt_type_group atg
	on sea.appointment_type = atg.appointment_type
left join dw_dev.dev_jkizer_source.map_clinical_classes mcc
	on sea.appointment_type = mcc.appointment_type
left join dw_dev.dev_jkizer.dim_location dl
	on sea.elation_location_id = dl.location_id
where sea._idx = 1
and sea._is_deleted_record = 0
and sea._is_test_patient = 0
and sea._duplicate_appt_idx = 1