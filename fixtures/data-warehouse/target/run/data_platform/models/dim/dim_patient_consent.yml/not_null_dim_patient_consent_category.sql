
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select category
from dw_dev.dev_jkizer.dim_patient_consent
where category is null



  
  
      
    ) dbt_internal_test