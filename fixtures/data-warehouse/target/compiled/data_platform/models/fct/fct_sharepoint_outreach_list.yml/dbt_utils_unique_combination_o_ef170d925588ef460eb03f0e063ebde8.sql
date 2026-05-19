





with validation_errors as (

    select
        suvida_id, snapshot_date, attempt
    from dw_dev.dev_jkizer.fct_sharepoint_outreach_list
    group by suvida_id, snapshot_date, attempt
    having count(*) > 1

)

select *
from validation_errors


