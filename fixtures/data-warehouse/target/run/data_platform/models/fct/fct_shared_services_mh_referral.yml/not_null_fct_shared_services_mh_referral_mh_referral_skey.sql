
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select mh_referral_skey
from dw_dev.dev_jkizer.fct_shared_services_mh_referral
where mh_referral_skey is null



  
  
      
    ) dbt_internal_test