





with validation_errors as (

    select
        airtable_id, last_modified_at
    from dw_dev.dev_jkizer.fct_shared_services_nutrition_referral
    group by airtable_id, last_modified_at
    having count(*) > 1

)

select *
from validation_errors


