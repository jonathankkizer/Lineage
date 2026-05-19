
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select all_orders_skey
from dw_dev.dev_jkizer.intmdt_elation_all_orders
where all_orders_skey is null



  
  
      
    ) dbt_internal_test