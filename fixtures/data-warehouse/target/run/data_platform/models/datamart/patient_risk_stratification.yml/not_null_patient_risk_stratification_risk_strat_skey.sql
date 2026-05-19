
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select risk_strat_skey
from dw_dev.dev_jkizer.patient_risk_stratification
where risk_strat_skey is null



  
  
      
    ) dbt_internal_test