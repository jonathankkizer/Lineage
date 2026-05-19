
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select appointment_skey
from dw_dev.dev_jkizer.fct_schedule_block_appointment
where appointment_skey is null



  
  
      
    ) dbt_internal_test