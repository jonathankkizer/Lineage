
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transaction_id
from dw_dev.dev_jkizer_staging.stg_candid_health_export_transaction
where transaction_id is null



  
  
      
    ) dbt_internal_test