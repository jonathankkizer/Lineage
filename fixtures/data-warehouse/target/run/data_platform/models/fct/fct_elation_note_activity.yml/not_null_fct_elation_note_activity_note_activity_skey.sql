
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select note_activity_skey
from dw_dev.dev_jkizer.fct_elation_note_activity
where note_activity_skey is null



  
  
      
    ) dbt_internal_test