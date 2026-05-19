
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_id
from dw_dev.dev_jkizer_staging.stg_talkdesk_contact_call
where user_id is null



  
  
      
    ) dbt_internal_test