
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    custom_block_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_elation_current_custom_block
where custom_block_skey is not null
group by custom_block_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test