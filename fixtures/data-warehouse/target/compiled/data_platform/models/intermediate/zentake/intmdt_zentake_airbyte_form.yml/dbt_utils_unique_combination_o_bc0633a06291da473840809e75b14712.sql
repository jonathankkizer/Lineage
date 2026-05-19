





with validation_errors as (

    select
        response_id, question_id, question_answer
    from dw_dev.dev_jkizer.intmdt_zentake_airbyte_form
    group by response_id, question_id, question_answer
    having count(*) > 1

)

select *
from validation_errors


