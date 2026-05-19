
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select lab_result_skey
from dw_dev.dev_jkizer.fct_lab_result
where lab_result_skey is null



  
  
      
    ) dbt_internal_test