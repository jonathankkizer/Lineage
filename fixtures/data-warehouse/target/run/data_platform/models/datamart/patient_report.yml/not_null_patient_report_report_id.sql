
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select report_id
from dw_dev.dev_jkizer.patient_report
where report_id is null



  
  
      
    ) dbt_internal_test