
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select member_id
from dw_dev.dev_jkizer.intmdt_alignment_financial_membership
where member_id is null



  
  
      
    ) dbt_internal_test