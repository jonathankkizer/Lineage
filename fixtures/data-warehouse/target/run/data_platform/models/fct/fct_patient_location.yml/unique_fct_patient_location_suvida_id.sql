
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    suvida_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_patient_location
where suvida_id is not null
group by suvida_id
having count(*) > 1



  
  
      
    ) dbt_internal_test