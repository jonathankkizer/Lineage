
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select type
from dw_dev.dev_jkizer_staging.stg_talkdesk_call
where type is null



  
  
      
    ) dbt_internal_test