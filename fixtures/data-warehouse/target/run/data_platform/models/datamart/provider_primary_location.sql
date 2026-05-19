
  
    

create or replace transient table dw_dev.dev_jkizer.provider_primary_location
    copy grants
    
    
    as (with 
cte_appointment_rank as (
SELECT
    seu.npi,
	seu.user_id as elation_user_id,
	seu.user_name,
    apt.elation_location_id,
    COUNT(*) AS appointment_count,
    row_number() OVER (PARTITION BY seu.npi ORDER BY COUNT(*) DESC ,max(apt.appointment_datetime) DESC) AS rn
  from dw_dev.dev_jkizer_staging.stg_elation_user seu
  join dw_dev.dev_jkizer_staging.stg_elation_appointment apt ON seu.user_id  =  apt.physician_id
  where len(npi) > 1
  group by
    seu.npi,seu.user_id, seu.user_name, apt.elation_location_id
  having count(*) > 10
)

select distinct car.npi,
  car.user_name,
  car.elation_location_id, 
  coalesce(sloc.name,'Virtual') as name, 
  coalesce(sloc.city,'Virtual') as city,
  coalesce(sloc.state ,'Virtual') as state
from cte_appointment_rank car
left join elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.service_location  sloc 
  on sloc.id = car.elation_location_id
where rn =1
    )
;


  