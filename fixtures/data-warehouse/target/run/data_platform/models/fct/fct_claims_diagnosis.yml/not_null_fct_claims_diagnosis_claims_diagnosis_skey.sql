
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select claims_diagnosis_skey
from dw_dev.dev_jkizer.fct_claims_diagnosis
where claims_diagnosis_skey is null



  
  
      
    ) dbt_internal_test