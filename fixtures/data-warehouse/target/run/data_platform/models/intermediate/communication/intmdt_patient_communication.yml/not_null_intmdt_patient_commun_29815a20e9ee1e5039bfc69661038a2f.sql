
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select patient_communication_skey
from dw_dev.dev_jkizer.intmdt_patient_communication
where patient_communication_skey is null



  
  
      
    ) dbt_internal_test