
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    problem_list_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_problem_list
where problem_list_skey is not null
group by problem_list_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test