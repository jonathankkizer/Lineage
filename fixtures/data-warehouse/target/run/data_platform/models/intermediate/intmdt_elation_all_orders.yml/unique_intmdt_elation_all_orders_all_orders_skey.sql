
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    all_orders_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.intmdt_elation_all_orders
where all_orders_skey is not null
group by all_orders_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test