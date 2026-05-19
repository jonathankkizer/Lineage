
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select census_event_id
from dw_dev.dev_jkizer.fct_census_event
where census_event_id is null



  
  
      
    ) dbt_internal_test