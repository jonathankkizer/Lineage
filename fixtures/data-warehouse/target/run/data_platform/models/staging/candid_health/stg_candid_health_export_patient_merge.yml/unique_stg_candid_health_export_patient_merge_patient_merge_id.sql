
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    patient_merge_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_patient_merge
where patient_merge_id is not null
group by patient_merge_id
having count(*) > 1



  
  
      
    ) dbt_internal_test