
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        airtable_id, last_modified_at
    from dw_dev.dev_jkizer.fct_shared_services_pt_referral
    group by airtable_id, last_modified_at
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test