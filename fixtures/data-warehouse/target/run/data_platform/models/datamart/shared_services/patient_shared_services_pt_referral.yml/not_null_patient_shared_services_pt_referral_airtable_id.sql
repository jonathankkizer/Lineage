
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select airtable_id
from dw_dev.dev_jkizer.patient_shared_services_pt_referral
where airtable_id is null



  
  
      
    ) dbt_internal_test