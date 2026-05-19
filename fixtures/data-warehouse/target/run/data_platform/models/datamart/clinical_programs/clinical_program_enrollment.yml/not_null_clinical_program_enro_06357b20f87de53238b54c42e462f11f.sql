
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select clinical_program_enrollment_skey
from dw_dev.dev_jkizer.clinical_program_enrollment
where clinical_program_enrollment_skey is null



  
  
      
    ) dbt_internal_test