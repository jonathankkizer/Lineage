
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_schedule_block
    copy grants
    
    
    as (/*
    Intermediate model: Combines schedule blocks from two sources into a unified format.

    Source 1: Recurring event groups (schedule templates expanded to individual dates)
    Source 2: "Other Event" type appointments used as ad-hoc schedule blocks

    This model handles:
    - Expanding weekly and monthly (4-week) recurring schedules into date-level rows
    - Unioning ad-hoc "Other Event" appointments as schedule blocks
    - Deduplication of overlapping recurring schedule definitions
    - Filtering out deleted schedule blocks

    Grain: One row per physician × event date × recurring schedule × event description
*/

with week_day_status as (
    /* Unpivot day-of-week flags from recurring event groups into a normalized format */
    select schedule_id, 1 as day_of_week, cast(dow_sunday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
    union all
    select schedule_id, 2 as day_of_week, cast(dow_monday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
    union all
    select schedule_id, 3 as day_of_week, cast(dow_tuesday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
    union all
    select schedule_id, 4 as day_of_week, cast(dow_wednesday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
    union all
    select schedule_id, 5 as day_of_week, cast(dow_thursday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
    union all
    select schedule_id, 6 as day_of_week, cast(dow_friday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
    union all
    select schedule_id, 7 as day_of_week, cast(dow_saturday as boolean) as day_of_week_status
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group

), recurring_weekly as (
    /* Expand weekly recurring schedules: one row per applicable day within the series date range */
    select
        dd.date_day as event_date,
        g.physician_id,
        g.id as recurring_event_id,
        to_time(g.event_time) as event_time,
        g.schedule_description as event_description,
        g.event_duration,
        g.schedule_created_date,
        g.created_date as creation_date,
        g.deleted_date,
        'recurring' as block_source
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group g
    inner join dw_dev.dev_jkizer.dim_date dd
        on dd.date_day >= to_date(g.series_start)
        and dd.date_day < coalesce(to_date(g.series_stop), to_date(extract(year from current_date()) + 1 || '-01-01'))
    inner join week_day_status wds
        on dd.day_of_week = wds.day_of_week
        and g.schedule_id = wds.schedule_id
    where g.repeat_interval = 'Weekly'
    and wds.day_of_week_status = 1

), recurring_monthly as (
    /* Expand monthly recurring schedules.
       Elation's "Monthly" means "the Nth weekday of each month" (e.g. 2nd Thursday),
       not every 28 days. We match on week-of-month position: ceil(day_of_month / 7)
       gives the occurrence number (1st, 2nd, 3rd, etc.) of that weekday. The
       week_day_status join already filters to the correct day of week. */
    select
        dd.date_day as event_date,
        g.physician_id,
        g.id as recurring_event_id,
        to_time(g.event_time) as event_time,
        g.schedule_description as event_description,
        g.event_duration,
        g.schedule_created_date,
        g.created_date as creation_date,
        g.deleted_date,
        'recurring' as block_source
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group g
    inner join dw_dev.dev_jkizer.dim_date dd
        on dd.date_day >= to_date(g.series_start)
        and dd.date_day < coalesce(to_date(g.series_stop), to_date(extract(year from current_date()) + 1 || '-01-01'))
        and ceil(dayofmonth(dd.date_day) / 7.0) = ceil(dayofmonth(to_date(g.series_start)) / 7.0)
    inner join week_day_status wds
        on dd.day_of_week = wds.day_of_week
        and g.schedule_id = wds.schedule_id
    where g.repeat_interval = 'Monthly'
    and wds.day_of_week_status = 1

), recurring_blocks as (
    select * from recurring_weekly
    union all
    select * from recurring_monthly

), recurring_segment_dedup as (
    /* First pass: deduplicate overlapping segments within the same recurring event
       (grouped by recurring_event_id). When Elation edits a recurring event, it
       creates new segments that may overlap existing ones with different event_time or
       duration. We keep the most recently created segment (by schedule_created_date)
       which reflects the current state. */
    select *
    from recurring_blocks
    where deleted_date is null
    qualify row_number() over (
        partition by physician_id, event_date, recurring_event_id
        order by schedule_created_date desc
    ) = 1

), recurring_deduplicated as (
    /* Second pass: deduplicate across different recurring event IDs. Admins sometimes
       create multiple recurring event groups for the same logical block (same provider,
       date, time, and description). Keep the most recently created group. */
    select
        event_date,
        physician_id,
        event_time,
        event_description,
        event_duration,
        creation_date,
        block_source
    from recurring_segment_dedup
    qualify row_number() over (
        partition by physician_id, event_date, event_time, event_description
        order by creation_date desc
    ) = 1

), other_event_blocks as (
    /* Ad-hoc schedule blocks from "Other Event" type appointments */
    select
        sea.appointment_date as event_date,
        seu.physician_id,
        sea.appointment_time as event_time,
        sea.appointment_description as event_description,
        sea.appointment_duration as event_duration,
        sea.creation_date,
        'other_event' as block_source
    from dw_dev.dev_jkizer_staging.stg_elation_appointment sea
    inner join dw_dev.dev_jkizer_staging.stg_elation_user seu
        on sea.physician_id = seu.user_id
    where sea.appointment_type = 'Other Event'
    and sea._idx = 1
    and sea._is_deleted_record = 0
    and seu.npi != '.'

)

select * from recurring_deduplicated
union all
select * from other_event_blocks
    )
;


  