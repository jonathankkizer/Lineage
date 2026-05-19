
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select integration_skey
from dw_dev.dev_jkizer.int_outreach_patient
where integration_skey is null



  
  
      
    ) dbt_internal_test