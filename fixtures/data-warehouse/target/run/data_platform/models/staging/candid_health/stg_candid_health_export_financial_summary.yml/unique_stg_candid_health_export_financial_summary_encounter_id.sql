
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    encounter_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_financial_summary
where encounter_id is not null
group by encounter_id
having count(*) > 1



  
  
      
    ) dbt_internal_test