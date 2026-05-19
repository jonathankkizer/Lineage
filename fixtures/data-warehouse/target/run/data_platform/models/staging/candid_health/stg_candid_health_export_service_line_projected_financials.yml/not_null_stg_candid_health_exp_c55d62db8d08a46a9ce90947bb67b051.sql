
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select service_line_id
from dw_dev.dev_jkizer_staging.stg_candid_health_export_service_line_projected_financials
where service_line_id is null



  
  
      
    ) dbt_internal_test