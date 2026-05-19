
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select lab_order_skey
from dw_dev.dev_jkizer.fct_lab_order
where lab_order_skey is null



  
  
      
    ) dbt_internal_test