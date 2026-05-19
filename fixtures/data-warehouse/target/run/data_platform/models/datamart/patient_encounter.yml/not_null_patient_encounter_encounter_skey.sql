
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select encounter_skey
from dw_dev.dev_jkizer.patient_encounter
where encounter_skey is null



  
  
      
    ) dbt_internal_test