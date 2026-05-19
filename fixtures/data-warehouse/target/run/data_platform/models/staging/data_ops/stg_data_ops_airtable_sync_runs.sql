
  create or replace   view dw_dev.dev_jkizer_staging.stg_data_ops_airtable_sync_runs
  
  copy grants
  
  
  as (
    with base as (
    select
        convert_timezone(
            'UTC',
            'America/Chicago',
            try_to_timestamp_ntz(run_datetime)
        ) as run_at,
        created_count,
        updated_count,
        deleted_count,
        airtable_process
    from source_prod.airtable.sync_audit
),

cleaned as (
    select
        *,
        created_count + updated_count + deleted_count as total_records_affected,
        (created_count + updated_count + deleted_count) > 0 as has_activity
    from base
    where run_at is not null
)

select * from cleaned
  );

