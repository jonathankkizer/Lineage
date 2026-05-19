
  
    

create or replace transient table dw_dev.dev_jkizer.fct_lab_result
    copy grants
    
    
    as (select 
	md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elr.lab_report_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elr.lab_result_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elo.lab_order_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as lab_result_skey,
	siw.suvida_id,
	coalesce(elo.elation_id, ser.patient_id) as elation_id,
	coalesce(elo.lab_report_id, ser.report_id) as report_id,
	elo.lab_order_id,
	elo.lab_vendor,
	elo.date_for_test,
	coalesce(elo.creation_date_time, ser.creation_datetime) as creation_date_time,
	coalesce(elo.creation_date, to_date(ser.creation_datetime)) as creation_date,
	coalesce(elo.signed_date, to_date(ser.signed_datetime)) as order_signed_date,
	coalesce(elo.signed_datetime, ser.signed_datetime) as order_signed_datetime,
    elr.lab_result_id,
	elr.test_category,
	elr.test_name,
	elr.test_value,
  	try_cast(replace(elr.test_value, '%', '') as float) as numeric_test_value,
	elr.loinc,
	elr.collected_date,
	elr.collected_date_time,
	elr.resulted_date,
	elr.resulted_datetime,
	elr.value_type,
	elr.value_note,
	elr.note,
from dw_dev.dev_jkizer_staging.stg_elation_lab_result elr
left join dw_dev.dev_jkizer_staging.stg_elation_lab_order elo
	on elr.lab_report_id = elo.lab_report_id
	and elo.deletion_date is null
left join dw_dev.dev_jkizer_staging.stg_elation_report ser 
	on elr.lab_report_id = ser.report_id
	and ser.deletion_datetime is null
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on coalesce(elo.elation_id, ser.patient_id) = siw.member_id
	and siw.source = 'Elation' 
where elr.is_deleted = false
    )
;


  