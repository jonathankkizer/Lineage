
  
    

create or replace transient table dw_dev.dev_jkizer.fct_quality_review_activity
    copy grants
    
    
    as (with activity_source as (
    select
        quality_measure_skey,
        airtable_id,
        last_modified_datetime,
        date(last_modified_datetime) as modified_date,
        workflow_status_detail,
        workflow_note,
        workflow_attachment,
        check_again_date,
        last_modified_by_name,
        lower(last_modified_by_email) as last_modified_by_email,
        osteo_fracture_date,
        is_automated_activity,
        workflow_status_index,
        run_datetime,
    from dw_dev.dev_jkizer_staging.stg_airtable_workflow_part_c
    qualify row_number() over (
        partition by
            airtable_id,
            last_modified_datetime,
            coalesce(workflow_status_detail, '__NULL__'),
            coalesce(workflow_note, '__NULL__'),
            coalesce(lower(last_modified_by_email), '__NULL__')
        order by run_datetime desc nulls last
    ) = 1
),

activity_changes as (
    select
        *,
        row_number() over (
            partition by airtable_id
            order by
                last_modified_datetime,
                run_datetime,
                coalesce(workflow_status_detail, ''),
                coalesce(workflow_note, '')
        ) as event_seq,
        case
            when workflow_status_detail is distinct from lag(workflow_status_detail) over (
                partition by airtable_id
                order by
                    last_modified_datetime,
                    run_datetime,
                    coalesce(workflow_status_detail, ''),
                    coalesce(workflow_note, '')
            )
            then 1 else 0
        end as status_detail_changed,
        case
            when workflow_note is distinct from lag(workflow_note) over (
                partition by airtable_id
                order by
                    last_modified_datetime,
                    run_datetime,
                    coalesce(workflow_status_detail, ''),
                    coalesce(workflow_note, '')
            )
            then 1 else 0
        end as workflow_note_changed
    from activity_source
),

daily_bounds as (
    select
        *,
        min(case when status_detail_changed = 1 then event_seq end) over (
            partition by airtable_id, modified_date, last_modified_by_email
        ) as first_status_change_seq,
        min(case when workflow_note_changed = 1 then event_seq end) over (
            partition by airtable_id, modified_date, last_modified_by_email
        ) as first_note_change_seq
    from activity_changes
)

select
    md5(cast(coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_modified_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(run_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(workflow_status_detail as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(workflow_note as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_modified_by_email as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as activity_key,
    quality_measure_skey,
    airtable_id,
    last_modified_datetime,
    workflow_status_detail,
    workflow_note,
    workflow_attachment,
    check_again_date,
    last_modified_by_name,
    last_modified_by_email,
    osteo_fracture_date,
    is_automated_activity,
    workflow_status_index,
    run_datetime,
    case
        when is_automated_activity then false
        when first_status_change_seq is not null
            and first_note_change_seq is not null
            and event_seq = greatest(first_status_change_seq, first_note_change_seq)
        then true
        else false
    end as is_qualifying_review
from daily_bounds
    )
;


  