
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    contact_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_talkdesk_contact_call
where contact_id is not null
group by contact_id
having count(*) > 1



  
  
      
    ) dbt_internal_test