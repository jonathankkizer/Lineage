
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select letter_id
from dw_dev.dev_jkizer_staging.stg_elation_relay_letter
where letter_id is null



  
  
      
    ) dbt_internal_test