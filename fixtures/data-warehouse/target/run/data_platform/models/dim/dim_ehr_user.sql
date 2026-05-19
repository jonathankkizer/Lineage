
  
    

create or replace transient table dw_dev.dev_jkizer.dim_ehr_user
    copy grants
    
    
    as (select
	seu.user_id,
	seu.office_staff_id as user_staff_id,
	seu.user_email,
	seu.user_name,
	seu.user_first_name,
	seu.user_last_name,
	seu.user_type,
	seu.specialty_desc,
	seu.credentials,
	seu.is_active,
from dw_dev.dev_jkizer_staging.stg_elation_user seu
where seu.npi is null -- non-NPI licensed roles; NPIs will be in dim_provider
and seu._idx = 1
    )
;


  