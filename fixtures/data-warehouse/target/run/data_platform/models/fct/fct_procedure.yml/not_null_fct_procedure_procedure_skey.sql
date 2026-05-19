
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select procedure_skey
from dw_dev.dev_jkizer.fct_procedure
where procedure_skey is null



  
  
      
    ) dbt_internal_test