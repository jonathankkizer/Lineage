
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select suvida_id
from dw_dev.dev_jkizer.fct_mmr_cap_period_process
where suvida_id is null



  
  
      
    ) dbt_internal_test