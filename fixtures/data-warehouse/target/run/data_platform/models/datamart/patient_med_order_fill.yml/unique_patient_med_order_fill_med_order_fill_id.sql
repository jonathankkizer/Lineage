
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    med_order_fill_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_med_order_fill
where med_order_fill_id is not null
group by med_order_fill_id
having count(*) > 1



  
  
      
    ) dbt_internal_test