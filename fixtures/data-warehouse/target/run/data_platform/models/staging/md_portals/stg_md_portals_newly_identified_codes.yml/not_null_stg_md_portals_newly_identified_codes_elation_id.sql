
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select elation_id
from dw_dev.dev_jkizer_staging.stg_md_portals_newly_identified_codes
where elation_id is null



  
  
      
    ) dbt_internal_test