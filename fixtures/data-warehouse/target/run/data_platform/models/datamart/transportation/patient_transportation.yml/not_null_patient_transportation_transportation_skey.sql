
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transportation_skey
from dw_dev.dev_jkizer.patient_transportation
where transportation_skey is null



  
  
      
    ) dbt_internal_test