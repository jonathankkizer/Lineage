
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select data_source_flag
from dw_dev.dev_jkizer.patient_inpatient_encounter
where data_source_flag is null



  
  
      
    ) dbt_internal_test