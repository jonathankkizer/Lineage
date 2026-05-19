
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    clinical_program_step_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.clinical_program_process_overview
where clinical_program_step_skey is not null
group by clinical_program_step_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test