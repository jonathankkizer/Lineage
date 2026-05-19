
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select airtable_id
from dw_dev.dev_jkizer.fct_shared_services_pharmd_referral
where airtable_id is null



  
  
      
    ) dbt_internal_test