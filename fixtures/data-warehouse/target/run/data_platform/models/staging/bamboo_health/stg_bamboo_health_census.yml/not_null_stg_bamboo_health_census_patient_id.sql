
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_id
from dw_dev.dev_jkizer_staging.stg_bamboo_health_census
where patient_id is null



  
  
      
    ) dbt_internal_test