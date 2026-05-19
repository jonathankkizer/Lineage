
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    appointment_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_appointment
where appointment_skey is not null
group by appointment_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test