
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select member_file_skey
from dw_dev.dev_jkizer_staging.stg_alignment_mmr
where member_file_skey is null



  
  
      
    ) dbt_internal_test