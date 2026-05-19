
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select icd_10_code
from dw_dev.dev_jkizer.fct_mdportals_diagnosis
where icd_10_code is null



  
  
      
    ) dbt_internal_test