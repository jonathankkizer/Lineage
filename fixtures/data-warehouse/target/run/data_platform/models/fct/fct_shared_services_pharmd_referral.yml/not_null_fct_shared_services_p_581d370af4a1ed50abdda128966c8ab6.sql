
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select pharmd_referral_skey
from dw_dev.dev_jkizer.fct_shared_services_pharmd_referral
where pharmd_referral_skey is null



  
  
      
    ) dbt_internal_test