
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id
from dw_prod.dw.intmdt_teams_call_record
where id is null



  
  
      
    ) dbt_internal_test