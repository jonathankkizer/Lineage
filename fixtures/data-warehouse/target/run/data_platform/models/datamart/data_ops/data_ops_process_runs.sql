
  
    

create or replace transient table dw_dev.dev_jkizer.data_ops_process_runs
    copy grants
    
    
    as (/* Daily summary of all data ops processes */

with events as (
    select * from dw_dev.dev_jkizer.data_ops_event_log
),

/* Airtable sync has explicit created/updated/deleted counts per run */
airtable_daily as (
    select
        run_at::date as run_date,
        'airtable_sync' as process_category,
        'airtable_' || airtable_process as process_name,
        count(*) as total_events,
        count(*) as success_count,
        0 as failure_count,
        sum(created_count) as records_created,
        sum(updated_count) as records_updated,
        sum(deleted_count) as records_deleted,
        max(run_at)::timestamp_ntz as last_event_at
    from dw_dev.dev_jkizer_staging.stg_data_ops_airtable_sync_runs
    group by 1, 2, 3
),

/* All other processes aggregated from the event log */
other_daily as (
    select
        event_date as run_date,
        process_category,
        process_name,
        count(*) as total_events,
        count_if(is_success = true) as success_count,
        count_if(is_success = false) as failure_count,
        sum(record_count) as records_created,
        0 as records_updated,
        0 as records_deleted,
        max(event_at)::timestamp_ntz as last_event_at
    from events
    where process_category != 'airtable_sync'
    group by 1, 2, 3
),

combined as (
    select * from airtable_daily
    union all
    select * from other_daily
)

select
    run_date,
    process_category,
    process_name,
    total_events,
    success_count,
    failure_count,
    records_created,
    records_updated,
    records_deleted,
    last_event_at
from combined
order by run_date desc, process_category, process_name
    )
;


  