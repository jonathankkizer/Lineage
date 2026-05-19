
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_profile_id
from dw_dev.dev_jkizer.dim_awell_patient
where patient_profile_id is null



  
  
      
    ) dbt_internal_test