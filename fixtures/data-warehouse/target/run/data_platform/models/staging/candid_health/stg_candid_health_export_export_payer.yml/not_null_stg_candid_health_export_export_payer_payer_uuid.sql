
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payer_uuid
from dw_dev.dev_jkizer_staging.stg_candid_health_export_export_payer
where payer_uuid is null



  
  
      
    ) dbt_internal_test