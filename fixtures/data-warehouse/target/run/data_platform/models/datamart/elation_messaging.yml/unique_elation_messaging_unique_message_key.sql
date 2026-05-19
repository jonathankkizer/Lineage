
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    unique_message_key as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.elation_messaging
where unique_message_key is not null
group by unique_message_key
having count(*) > 1



  
  
      
    ) dbt_internal_test