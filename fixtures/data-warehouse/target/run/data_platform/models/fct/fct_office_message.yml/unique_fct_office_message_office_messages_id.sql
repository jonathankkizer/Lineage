
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    office_messages_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_office_message
where office_messages_id is not null
group by office_messages_id
having count(*) > 1



  
  
      
    ) dbt_internal_test