
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select census_event_skey
from dw_dev.dev_jkizer.patient_census_event
where census_event_skey is null



  
  
      
    ) dbt_internal_test