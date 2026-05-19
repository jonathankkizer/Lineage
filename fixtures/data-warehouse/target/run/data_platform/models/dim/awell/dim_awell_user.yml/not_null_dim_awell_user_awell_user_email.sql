
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select awell_user_email
from dw_dev.dev_jkizer.dim_awell_user
where awell_user_email is null



  
  
      
    ) dbt_internal_test