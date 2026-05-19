
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select nutrition_referral_skey
from dw_dev.dev_jkizer.fct_shared_services_nutrition_referral
where nutrition_referral_skey is null



  
  
      
    ) dbt_internal_test