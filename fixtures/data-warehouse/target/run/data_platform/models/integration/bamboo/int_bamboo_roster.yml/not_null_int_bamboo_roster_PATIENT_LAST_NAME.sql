
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select PATIENT_LAST_NAME
from dw_dev.dev_jkizer.int_bamboo_roster
where PATIENT_LAST_NAME is null



  
  
      
    ) dbt_internal_test