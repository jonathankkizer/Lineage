with week_day_status as ( /*Create a week record for each day of the week in the configuration*/
     select
        schedule_id,
        1 as day_of_week,
        cast(dow_sunday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
	 union all
	 select
        schedule_id,
        2 as day_of_week,
        cast(dow_monday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
     union all
     select
        schedule_id,
        3 as day_of_week,
        cast(dow_tuesday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
     union all
     select
        schedule_id,
        4 as day_of_week,
        cast(dow_wednesday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
     union all
     select
        schedule_id,
        5 as day_of_week,
        cast(dow_thursday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
     union all
     select
        schedule_id,
        6 as day_of_week,
        cast(dow_friday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
     union all
     select
        schedule_id,
        7 as day_of_week,
        cast(dow_saturday as boolean) as day_of_week_status
     from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group
), schedule_blocks as (
    select
        dd.date_day as event_date,
        g.physician_id,
        g.id as recurring_event_id,
        to_time(g.event_time) as event_time,
        g.schedule_description,
        event_duration,
        g.schedule_created_date,
	    g.created_date as creation_date,
        g.deleted_date
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group g
    inner join dw_dev.dev_jkizer.dim_date dd
        on dd.date_day >= to_date(g.series_start)
        and dd.date_day < coalesce(to_date(g.series_stop), to_date(extract(year from current_date()) + 1 || '-01-01'))
    inner join week_day_status wds
        on dd.day_of_week = wds.day_of_week
        and g.schedule_id = wds.schedule_id
    where repeat_interval = 'Weekly'
    and wds.day_of_week_status = 1
    
    union all
    
    select
        dd.date_day as event_date,
        g.physician_id,
        g.id as recurring_event_id,
        to_time(g.event_time) as event_time,
        g.schedule_description,
        event_duration,
        g.schedule_created_date,
	    g.created_date as creation_date,
        g.deleted_date
    from dw_dev.dev_jkizer_staging.stg_ehd_recurring_event_group g
    inner join dw_dev.dev_jkizer.dim_date dd
        on dd.date_day >= to_date(g.series_start)
        and dd.date_day < coalesce(to_date(g.series_stop), to_date(extract(year from current_date()) + 1 || '-01-01'))
	    and ceil(dayofmonth(dd.date_day) / 7.0) = ceil(dayofmonth(to_date(g.series_start)) / 7.0)
    inner join week_day_status wds
        on dd.day_of_week = wds.day_of_week
        and g.schedule_id = wds.schedule_id
    where  repeat_interval = 'Monthly'
    and wds.day_of_week_status = 1
), segment_dedup as (
    /* First pass: deduplicate overlapping segments within the same recurring event */
    select *
    from schedule_blocks
    where deleted_date is null
    qualify row_number() over (
        partition by physician_id, event_date, recurring_event_id
        order by schedule_created_date desc
    ) = 1

), cross_event_dedup as (
    /* Second pass: deduplicate across different recurring event IDs for the same
       logical block (same provider, date, time, and description) */
    select *
    from segment_dedup
    qualify row_number() over (
        partition by physician_id, event_date, event_time, schedule_description
        order by creation_date desc
    ) = 1

), timezone_logic as (
    select
        dp.location_name,
        dp.provider_name,
        dp.npi,
        dp.specialty_desc,
        dp.is_actively_seeing_patients,
        dp.provider_type,
        iff(dp.location_state = 'AZ',
            timestamp_tz_from_parts(year(event_date), month(event_date), day(event_date), hour(event_time), minute(event_time), second(event_time), 0, 'America/Phoenix'),
            timestamp_tz_from_parts(year(event_date), month(event_date), day(event_date), hour(event_time), minute(event_time), second(event_time), 0, 'America/Chicago')
        ) as event_start_datetime,
        iff(dp.location_state = 'AZ',
            dateadd('minute', block_appt.event_duration, timestamp_tz_from_parts(year(event_date), month(event_date), day(event_date), hour(event_time), minute(event_time), second(event_time), 0, 'America/Phoenix')),
            dateadd('minute', block_appt.event_duration, timestamp_tz_from_parts(year(event_date), month(event_date), day(event_date), hour(event_time), minute(event_time), second(event_time), 0, 'America/Chicago'))
        ) as event_end_datetime,
        block_appt.physician_id,
        block_appt.event_date,
        block_appt.event_time,
        block_appt.event_duration,
        block_appt.schedule_description,
        block_appt.creation_date,
        block_appt.deleted_date,
    from cross_event_dedup block_appt
    inner join dw_dev.dev_jkizer.dim_provider dp
        on block_appt.physician_id = dp.physician_id -- removes non-provider schedules
), schedule_data as (
    select 
        md5(cast(coalesce(cast(physician_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(event_start_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(event_duration as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(schedule_description as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(creation_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as schedule_event_skey,
        location_name,
        provider_name,
        specialty_desc,
        is_actively_seeing_patients,
        provider_type,
        npi,
        physician_id,
        event_date,
        event_time,
        event_duration,
        event_start_datetime,
        dateadd('minute', event_duration, event_start_datetime) as event_end_datetime,
        convert_timezone('UTC', event_start_datetime) as event_start_datetime_utc,
        dateadd('minute', event_duration, convert_timezone('UTC', event_start_datetime)) as event_end_datetime_utc,
        schedule_description as event_description,
        creation_date,
        deleted_date,
    from timezone_logic
    
    union all
    
    select 
        md5(cast(coalesce(cast(seu.physician_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_duration as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_description as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(creation_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as schedule_event_skey,
        dp.location_name,
        dp.provider_name,
        dp.specialty_desc,
        dp.is_actively_seeing_patients,
        dp.provider_type,
        seu.npi,
        seu.physician_id,
        appointment_date as event_date,
        appointment_time as event_time,
        appointment_duration as event_duration,
        appointment_datetime as event_start_datetime,
        dateadd('minute', appointment_duration, appointment_datetime) as event_end_datetime,
        appointment_datetime_utc as event_start_datetime_utc,
        dateadd('minute', appointment_duration, appointment_datetime_utc) as event_end_datetime_utc,
        appointment_description as event_description,
        sea.creation_date,
        date(deletion_datetime) as deleted_date,
    from dw_dev.dev_jkizer_staging.stg_elation_appointment sea
    inner join dw_dev.dev_jkizer_staging.stg_elation_user seu 
        on sea.physician_id = seu.user_id
    inner join dw_dev.dev_jkizer.dim_provider dp 
        on seu.npi = dp.npi
    where appointment_type = 'Other Event'
    and sea._idx = 1
    and sea._is_deleted_record = 0
    and seu.npi != '.'
), overlapping_dns as (
    select 
        s1.schedule_event_skey,
        max(
            case 
            when lower(s2.event_description) like '%dns%' then true
            else false
            end
        ) as is_do_not_schedule,
    from schedule_data s1
    left join schedule_data s2
        on s1.physician_id = s2.physician_id
        and s1.event_start_datetime_utc >= s2.event_start_datetime_utc
        and s1.event_start_datetime_utc < s2.event_end_datetime_utc
    group by 1
)
select 
    *
from schedule_data sd 
left join overlapping_dns
    using (schedule_event_skey)