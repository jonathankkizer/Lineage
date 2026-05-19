
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select referral_id
from dw_dev.dev_jkizer_staging.stg_elation_relay_referral_order
where referral_id is null



  
  
      
    ) dbt_internal_test