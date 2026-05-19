
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    risk_strat_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_risk_stratification
where risk_strat_skey is not null
group by risk_strat_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test