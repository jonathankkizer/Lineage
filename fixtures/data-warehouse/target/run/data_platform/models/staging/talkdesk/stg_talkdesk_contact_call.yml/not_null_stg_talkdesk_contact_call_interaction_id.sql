
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select interaction_id
from dw_dev.dev_jkizer_staging.stg_talkdesk_contact_call
where interaction_id is null



  
  
      
    ) dbt_internal_test