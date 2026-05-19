
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    (concat(suvida_id, date_month)) as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_assignment
where (concat(suvida_id, date_month)) is not null
group by (concat(suvida_id, date_month))
having count(*) > 1



  
  
      
    ) dbt_internal_test