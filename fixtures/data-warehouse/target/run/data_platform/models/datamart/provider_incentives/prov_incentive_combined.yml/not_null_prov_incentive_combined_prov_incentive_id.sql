
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select prov_incentive_id
from dw_dev.dev_jkizer.prov_incentive_combined
where prov_incentive_id is null



  
  
      
    ) dbt_internal_test