
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_appointment_sandbox
    copy grants
    
    
    as (-- Get all past appointments for patients, as well as visit notes related to the appointments
select
    fa.appointment_id,
    fa.appointment_datetime_utc,
    fa.appointment_status,
    fa.appointment_completed_ind,
    fa.appointment_type,
    fa.visit_level,
    atg.visit_type,
    fa.appointment_provider_category as appointment_specialty,
    fa.appointment_description,
    md5(cast(coalesce(cast(fa.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as suvida_id,
    ipsu.elation_id,
    fa.physician_id,
    fa.appointment_provider_name,
    fa.appointment_duration,
    fa.visit_location_type,
    sea.elation_location_id,
    fa.appointment_location_name,
    fa.is_pcp_appt,
    fa.is_guia_appt,
    fa.is_mh_appt,
    fa.is_nutrition_appt,
    fa.is_pharmacy_appt,
    fa.is_pt_appt,
    fa.is_ma_appt,
    fa.is_virtual_appt
from dw_dev.dev_jkizer.fct_appointment fa
left join dw_dev.dev_jkizer.int_patient_summary_sandbox ipsu
    on md5(cast(coalesce(cast(fa.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) = ipsu.suvida_id
inner join dw_dev.dev_jkizer_staging.stg_elation_appointment sea
    on fa.appointment_id = sea.appointment_id
left join dw_dev.dev_jkizer_source.map_appt_type_group atg
    on fa.appointment_type = atg.appointment_type
where    
    ipsu.suvida_id is not null and
    fa.appointment_datetime_utc <= sysdate()
    )
;


  