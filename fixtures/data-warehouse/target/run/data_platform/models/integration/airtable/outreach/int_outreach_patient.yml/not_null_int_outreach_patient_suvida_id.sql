
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select suvida_id
from dw_dev.dev_jkizer.int_outreach_patient
where suvida_id is null



  
  
      
    ) dbt_internal_test