
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_merge_id
from dw_dev.dev_jkizer_staging.stg_candid_health_export_patient_merge
where patient_merge_id is null



  
  
      
    ) dbt_internal_test