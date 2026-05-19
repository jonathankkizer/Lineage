
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select referral_pk_id
from dw_dev.dev_jkizer.fct_leadingreach_referral
where referral_pk_id is null



  
  
      
    ) dbt_internal_test