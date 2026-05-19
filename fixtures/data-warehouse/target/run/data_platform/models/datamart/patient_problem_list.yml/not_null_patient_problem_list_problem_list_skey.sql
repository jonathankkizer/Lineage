
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select problem_list_skey
from dw_dev.dev_jkizer.patient_problem_list
where problem_list_skey is null



  
  
      
    ) dbt_internal_test