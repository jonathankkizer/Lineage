
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  





with validation_errors as (

    select
        response_id, question_id, question_answer
    from dw_dev.dev_jkizer.intmdt_zentake_airbyte_form
    group by response_id, question_id, question_answer
    having count(*) > 1

)

select *
from validation_errors



  
  
      
    ) dbt_internal_test