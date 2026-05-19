
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    census_event_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_census_event
where census_event_skey is not null
group by census_event_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test