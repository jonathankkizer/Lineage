
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select pt_referral_skey
from dw_dev.dev_jkizer.fct_shared_services_pt_referral
where pt_referral_skey is null



  
  
      
    ) dbt_internal_test