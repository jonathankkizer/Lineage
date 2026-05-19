
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select hcc_icd_id_skey
from dw_dev.dev_jkizer.fct_mdportals_diagnosis
where hcc_icd_id_skey is null



  
  
      
    ) dbt_internal_test