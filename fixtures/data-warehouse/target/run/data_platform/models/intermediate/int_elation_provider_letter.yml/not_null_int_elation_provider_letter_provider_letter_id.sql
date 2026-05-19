
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select provider_letter_id
from dw_dev.dev_jkizer.int_elation_provider_letter
where provider_letter_id is null



  
  
      
    ) dbt_internal_test