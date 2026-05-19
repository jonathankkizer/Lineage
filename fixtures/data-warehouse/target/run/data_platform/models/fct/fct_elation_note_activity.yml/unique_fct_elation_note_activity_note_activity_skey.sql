
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    note_activity_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_elation_note_activity
where note_activity_skey is not null
group by note_activity_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test