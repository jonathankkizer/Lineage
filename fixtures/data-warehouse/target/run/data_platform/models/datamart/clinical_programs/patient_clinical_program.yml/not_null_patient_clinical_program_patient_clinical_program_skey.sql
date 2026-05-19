
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_clinical_program_skey
from dw_dev.dev_jkizer.patient_clinical_program
where patient_clinical_program_skey is null



  
  
      
    ) dbt_internal_test