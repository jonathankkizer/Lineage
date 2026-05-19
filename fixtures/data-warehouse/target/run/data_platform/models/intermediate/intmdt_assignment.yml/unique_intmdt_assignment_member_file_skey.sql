
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    member_file_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.intmdt_assignment
where member_file_skey is not null
group by member_file_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test