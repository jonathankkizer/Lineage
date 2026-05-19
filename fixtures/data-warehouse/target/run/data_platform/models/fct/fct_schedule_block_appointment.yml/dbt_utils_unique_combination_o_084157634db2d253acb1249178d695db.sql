
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        schedule_block_skey, appointment_skey
    from dw_dev.dev_jkizer.fct_schedule_block_appointment
    group by schedule_block_skey, appointment_skey
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test