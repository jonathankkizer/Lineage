
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select diagnosis_skey
from dw_dev.dev_jkizer.patient_diagnosis_claims
where diagnosis_skey is null



  
  
      
    ) dbt_internal_test