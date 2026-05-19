
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select consent_skey
from dw_dev.dev_jkizer.fct_consent
where consent_skey is null



  
  
      
    ) dbt_internal_test