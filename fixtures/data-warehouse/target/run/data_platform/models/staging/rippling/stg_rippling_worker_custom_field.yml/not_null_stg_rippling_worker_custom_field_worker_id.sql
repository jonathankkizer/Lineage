
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select worker_id
from dw_dev.dev_jkizer_staging.stg_rippling_worker_custom_field
where worker_id is null



  
  
      
    ) dbt_internal_test