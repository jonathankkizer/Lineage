
  
    

create or replace transient table dw_dev.dev_jkizer.data_ops_event_log
    copy grants
    
    
    as (/* Unified event log across all data ops processes */

with vortex_events as (
    select
        event_at,
        process_category,
        process_name,
        action as event_action,
        is_success,
        coalesce(basename, filename) as entity_id,
        rule_name as entity_detail,
        1 as record_count,
        error as detail
    from dw_dev.dev_jkizer_staging.stg_data_ops_vortex_file_events
),

airtable_events as (
    select
        run_at as event_at,
        'airtable_sync' as process_category,
        'airtable_' || airtable_process as process_name,
        case
            when has_activity then 'sync_with_changes'
            else 'sync_no_changes'
        end as event_action,
        true as is_success,
        airtable_process as entity_id,
        null::varchar as entity_detail,
        total_records_affected as record_count,
        'created: ' || created_count || ', updated: ' || updated_count || ', deleted: ' || deleted_count as detail
    from dw_dev.dev_jkizer_staging.stg_data_ops_airtable_sync_runs
),

attestation_opportunity_events as (
    select
        event_at,
        'attestation_pipeline' as process_category,
        'attestation_opportunities' as process_name,
        event_action,
        true as is_success,
        suvida_id::varchar as entity_id,
        icd_10_code as entity_detail,
        1 as record_count,
        action || ' - ' || icd_10_code as detail
    from dw_dev.dev_jkizer_staging.stg_data_ops_attestation_events
),

attestation_action_events as (
    select
        event_at,
        'attestation_pipeline' as process_category,
        'attestation_physician_actions' as process_name,
        event_action,
        true as is_success,
        elation_id::varchar as entity_id,
        icd_10_code as entity_detail,
        1 as record_count,
        doctag as detail
    from dw_dev.dev_jkizer_staging.stg_data_ops_attestation_actions
),

insurance_events as (
    select
        event_at,
        'emr_insurance_update' as process_category,
        'insurance_updates' as process_name,
        'patched' as event_action,
        true as is_success,
        suvida_id::varchar as entity_id,
        elation_id::varchar as entity_detail,
        1 as record_count,
        null::varchar as detail
    from dw_dev.dev_jkizer_staging.stg_data_ops_insurance_updates
),

tag_events as (
    select
        event_at,
        'emr_tag_update' as process_category,
        'tag_updates' as process_name,
        'patched' as event_action,
        true as is_success,
        suvida_id::varchar as entity_id,
        elation_id::varchar as entity_detail,
        1 as record_count,
        null::varchar as detail
    from dw_dev.dev_jkizer_staging.stg_data_ops_tag_updates
),

unioned as (
    select * from vortex_events
    union all
    select * from airtable_events
    union all
    select * from attestation_opportunity_events
    union all
    select * from attestation_action_events
    union all
    select * from insurance_events
    union all
    select * from tag_events
)

select
    event_at,
    event_at::date as event_date,
    process_category,
    process_name,
    event_action,
    is_success,
    entity_id,
    entity_detail,
    record_count,
    detail
from unioned
where event_at is not null
    )
;


  