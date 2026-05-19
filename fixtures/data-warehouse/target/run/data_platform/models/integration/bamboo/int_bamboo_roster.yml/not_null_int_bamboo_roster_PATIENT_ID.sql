
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select PATIENT_ID
from dw_dev.dev_jkizer.int_bamboo_roster
where PATIENT_ID is null



  
  
      
    ) dbt_internal_test