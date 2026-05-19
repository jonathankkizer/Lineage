
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_period_skey
from dw_dev.dev_jkizer.patient_monthly
where patient_period_skey is null



  
  
      
    ) dbt_internal_test