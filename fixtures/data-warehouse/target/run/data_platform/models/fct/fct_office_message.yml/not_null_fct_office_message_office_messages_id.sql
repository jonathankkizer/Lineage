
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select office_messages_id
from dw_dev.dev_jkizer.fct_office_message
where office_messages_id is null



  
  
      
    ) dbt_internal_test