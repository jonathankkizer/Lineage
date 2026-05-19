
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select unique_message_key
from dw_dev.dev_jkizer.elation_messaging
where unique_message_key is null



  
  
      
    ) dbt_internal_test