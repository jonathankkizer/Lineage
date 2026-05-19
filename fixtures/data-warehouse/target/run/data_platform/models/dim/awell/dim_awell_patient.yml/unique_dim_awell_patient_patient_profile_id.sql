
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    patient_profile_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_awell_patient
where patient_profile_id is not null
group by patient_profile_id
having count(*) > 1



  
  
      
    ) dbt_internal_test