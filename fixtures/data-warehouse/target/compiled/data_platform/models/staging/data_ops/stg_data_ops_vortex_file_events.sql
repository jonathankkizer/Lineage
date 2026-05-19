with base as (
    select
        filename,
        try_to_number(size) as file_size,
        try_to_number(mtime) as mtime,
        basename,
        coalesce(
            try_to_timestamp_tz(actiondatetime),
            try_to_timestamp_ntz(actiondatetime)
        ) as event_at_raw,
        action,
        rule_name,
        destination_path,
        output_filename,
        sheet_name,
        try_to_number(row_count) as row_count,
        try_to_number(column_count) as column_count,
        part_number,
        conversion_type,
        error
    from source_prod.vortex.src_vortex_metadata
),

cleaned as (
    select
        *,
        convert_timezone('America/Chicago', event_at_raw::timestamp_ntz)::timestamp_ntz as event_at,
        case
            when action ilike '%postal%' then 'postal'
            else 'vortex'
        end as process_category,
        case
            when action ilike '%postal_sort%' then 'postal_sort'
            when action ilike '%postal_convert%' then 'postal_convert'
            when action ilike '%sftp%' or action ilike '%blob_storage%' then 'vortex_sftp_ingestion'
            else 'vortex_other'
        end as process_name,
        case
            when action ilike '%success%' or action = 'moved_from_sftp_to_blob_storage' then true
            when action ilike '%failed%' then false
            else null
        end as is_success
    from base
    where event_at_raw is not null
)

select * from cleaned