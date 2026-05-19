
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    awell_user_email as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_awell_user
where awell_user_email is not null
group by awell_user_email
having count(*) > 1



  
  
      
    ) dbt_internal_test