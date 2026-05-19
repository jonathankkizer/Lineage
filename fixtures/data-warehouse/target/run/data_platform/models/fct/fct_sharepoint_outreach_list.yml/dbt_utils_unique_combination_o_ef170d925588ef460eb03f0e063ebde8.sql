
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        suvida_id, snapshot_date, attempt
    from dw_dev.dev_jkizer.fct_sharepoint_outreach_list
    group by suvida_id, snapshot_date, attempt
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test