
    
    

select
    response_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_zentake_backfill_responses
where response_id is not null
group by response_id
having count(*) > 1


