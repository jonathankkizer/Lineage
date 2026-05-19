
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_consent_skey
from dw_dev.dev_jkizer.dim_patient_consent
where patient_consent_skey is null



  
  
      
    ) dbt_internal_test