
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select clinical_program_step_skey
from dw_dev.dev_jkizer.clinical_program_process_overview
where clinical_program_step_skey is null



  
  
      
    ) dbt_internal_test