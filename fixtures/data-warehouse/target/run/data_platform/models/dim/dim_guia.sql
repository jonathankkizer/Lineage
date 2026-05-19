
  
    

create or replace transient table dw_dev.dev_jkizer.dim_guia
    copy grants
    
    
    as (select
	md5(cast(coalesce(cast(cs.work_email as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as guia_skey,
	cs.full_name as guia_name,
	cs.work_email as guia_email_address,
	cs.title as rippling_title,
	cs.work_location as location_name, 
	cs.work_location_city as rippling_work_location_city,
	cs.work_location_state as rippling_work_location_state,
	cs.work_location_zip as rippling_work_location_zip,
	cs.location_description as rippling_location_description,
	sgd.guia_start_date,
	sgd.guia_end_date,
	sgd.tag_guia_role_name,
	sgd.user_id as guia_user_id,
from dw_dev.dev_jkizer.intmdt_rippling_clinical_staff cs
left join dw_dev.dev_jkizer_staging.stg_sharepoint_guia_directory sgd
	on sgd.guia_email_address = cs.work_email
where department = 'Guia Program'
and cs.is_active = true
    )
;


  