
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select encounter_id
from dw_dev.dev_jkizer.fct_candid_health_claims
where encounter_id is null



  
  
      
    ) dbt_internal_test