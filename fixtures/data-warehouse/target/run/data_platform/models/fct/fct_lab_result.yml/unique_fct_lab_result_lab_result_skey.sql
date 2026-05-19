
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    lab_result_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_lab_result
where lab_result_skey is not null
group by lab_result_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test