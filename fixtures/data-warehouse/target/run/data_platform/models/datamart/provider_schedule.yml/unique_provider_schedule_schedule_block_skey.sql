
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    schedule_block_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.provider_schedule
where schedule_block_skey is not null
group by schedule_block_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test