
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select callsid
from dw_dev.dev_jkizer.intmdt_talkdesk_call
where callsid is null



  
  
      
    ) dbt_internal_test