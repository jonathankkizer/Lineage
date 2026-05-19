
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        data_source_flag as value_field,
        count(*) as n_records

    from dw_dev.dev_jkizer.patient_inpatient_encounter
    group by data_source_flag

)

select *
from all_values
where value_field not in (
    'census','claims'
)



  
  
      
    ) dbt_internal_test