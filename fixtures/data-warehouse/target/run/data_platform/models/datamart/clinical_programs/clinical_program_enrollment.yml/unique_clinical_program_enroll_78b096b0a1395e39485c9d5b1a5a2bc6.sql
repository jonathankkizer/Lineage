
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    clinical_program_enrollment_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.clinical_program_enrollment
where clinical_program_enrollment_skey is not null
group by clinical_program_enrollment_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test