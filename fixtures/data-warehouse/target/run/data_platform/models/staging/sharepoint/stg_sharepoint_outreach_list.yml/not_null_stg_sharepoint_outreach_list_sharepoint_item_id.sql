
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sharepoint_item_id
from dw_dev.dev_jkizer_staging.stg_sharepoint_outreach_list
where sharepoint_item_id is null



  
  
      
    ) dbt_internal_test