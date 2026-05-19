
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select source_member_id
from dw_dev.dev_jkizer_staging.stg_wellmed_census
where source_member_id is null



  
  
      
    ) dbt_internal_test