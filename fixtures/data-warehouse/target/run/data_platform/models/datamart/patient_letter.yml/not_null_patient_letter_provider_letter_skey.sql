
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select provider_letter_skey
from dw_dev.dev_jkizer.patient_letter
where provider_letter_skey is null



  
  
      
    ) dbt_internal_test