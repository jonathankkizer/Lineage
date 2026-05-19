
  
    

create or replace transient table dw_dev.dev_jkizer.provider_third_next_available
    copy grants
    
    
    as (/*
    Datamart: Third next available appointment slot per provider, location, and slot type.

    Different grain from provider_schedule — one row per provider × location × slot type × duration category.
    Requires SQL because Lightdash cannot derive window-function-based ranking across slot types.

    Provides:
    - Next, second next, and third next available dates for 30-min and 60-min slots
    - Days to third next available (key access metric)
    - Broken out by slot type (new patient, established, TOC, same day) so access metrics
      are specific to appointment type
*/

with open_30_min_slots as (
    select
        schedule_block_skey,
        location_name,
        provider_name,
        npi,
        physician_id,
        provider_type,
        is_actively_seeing_patients,
        event_date,
        event_start_datetime,
        case
            when is_new_patient_slot     = true then 'New Patient'
            when is_established_slot     = true then 'Established'
            when is_toc_slot             = true then 'TOC'
            when is_same_day_slot        = true then 'Same Day'
            when is_open_scheduling_slot = true then 'Open Scheduling'
        end as slot_type,
        '30_min' as duration_category,
        row_number() over (
            partition by location_name, npi, is_new_patient_slot, is_established_slot, is_toc_slot, is_same_day_slot, is_open_scheduling_slot
            order by event_start_datetime asc
        ) as open_slot_rank
    from dw_dev.dev_jkizer.provider_schedule
    where is_open = true
    and event_start_datetime >= current_timestamp()
    qualify open_slot_rank <= 3

), open_60_min_slots as (
    select
        schedule_block_skey,
        location_name,
        provider_name,
        npi,
        physician_id,
        provider_type,
        is_actively_seeing_patients,
        event_date,
        event_start_datetime,
        case
            when is_new_patient_slot     = true then 'New Patient'
            when is_established_slot     = true then 'Established'
            when is_toc_slot             = true then 'TOC'
            when is_same_day_slot        = true then 'Same Day'
            when is_open_scheduling_slot = true then 'Open Scheduling'
        end as slot_type,
        '60_min' as duration_category,
        row_number() over (
            partition by location_name, npi, is_new_patient_slot, is_established_slot, is_toc_slot, is_same_day_slot, is_open_scheduling_slot
            order by event_start_datetime asc
        ) as open_slot_rank
    from dw_dev.dev_jkizer.provider_schedule
    where is_open_hour_block = true
    and event_start_datetime >= current_timestamp()
    qualify open_slot_rank <= 3

), all_open_slots as (
    select * from open_30_min_slots
    union all
    select * from open_60_min_slots

), pivoted as (
    select
        location_name,
        provider_name,
        npi,
        physician_id,
        provider_type,
        is_actively_seeing_patients,
        duration_category,
        slot_type,
        max(case when open_slot_rank = 1 then event_date end) as next_available_date,
        max(case when open_slot_rank = 1 then event_start_datetime end) as next_available_datetime,
        max(case when open_slot_rank = 2 then event_date end) as second_next_available_date,
        max(case when open_slot_rank = 2 then event_start_datetime end) as second_next_available_datetime,
        max(case when open_slot_rank = 3 then event_date end) as third_next_available_date,
        max(case when open_slot_rank = 3 then event_start_datetime end) as third_next_available_datetime,
        datediff('day', current_date(), max(case when open_slot_rank = 3 then event_date end)) as days_to_third_next_available
    from all_open_slots
    group by 1, 2, 3, 4, 5, 6, 7, 8
)

select * from pivoted
    )
;


  