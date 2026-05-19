
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select report_date
from dw_dev.dev_jkizer_staging.stg_wellcare_national_med_adherence
where report_date is null



  
  
      
    ) dbt_internal_test