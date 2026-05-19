
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    patient_tag_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_patient_tag
where patient_tag_skey is not null
group by patient_tag_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test