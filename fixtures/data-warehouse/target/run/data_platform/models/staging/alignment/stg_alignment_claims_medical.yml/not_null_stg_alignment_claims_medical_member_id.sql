
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select member_id
from dw_dev.dev_jkizer_staging.stg_alignment_claims_medical
where member_id is null



  
  
      
    ) dbt_internal_test