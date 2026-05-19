
  
    

create or replace transient table dw_dev.dev_jkizer.fct_schedule_block
    copy grants
    
    
    as (/*
    Fact table: Enriched schedule blocks with provider attributes, timezone handling,
    block type classification, DNS overlap detection, and contiguity flags.

    Built on intmdt_schedule_block (which unifies recurring + Other Event sources).

    Grain: One row per schedule block (physician × datetime × description)

    Includes time-based "flip" rules: designated blocks become open to same-day/any
    scheduling before the appointment time. Per business rules:
    - TOC blocks flip open 24 hours before
    - Established and New Patient blocks flip open 48 hours before
*/

with timezone_logic as (
    select
        dp.location_name,
        dp.provider_name,
        dp.npi,
        dp.specialty_desc,
        dp.is_actively_seeing_patients,
        dp.provider_type,
        dp.location_state,
        iff(dp.location_state = 'AZ',
            timestamp_tz_from_parts(year(b.event_date), month(b.event_date), day(b.event_date), hour(b.event_time), minute(b.event_time), second(b.event_time), 0, 'America/Phoenix'),
            timestamp_tz_from_parts(year(b.event_date), month(b.event_date), day(b.event_date), hour(b.event_time), minute(b.event_time), second(b.event_time), 0, 'America/Chicago')
        ) as event_start_datetime,
        b.physician_id,
        b.event_date,
        b.event_time,
        b.event_duration,
        b.event_description,
        b.creation_date,
        b.block_source
    from dw_dev.dev_jkizer.intmdt_schedule_block b
    inner join dw_dev.dev_jkizer.dim_provider dp
        on b.physician_id = dp.physician_id

), keyed_blocks as (
    select
        md5(cast(coalesce(cast(physician_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(event_start_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(event_duration as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(event_description as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(creation_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as schedule_block_skey,
        location_name,
        provider_name,
        npi,
        specialty_desc,
        is_actively_seeing_patients,
        provider_type,
        location_state,
        physician_id,
        event_date,
        event_time,
        event_duration,
        event_start_datetime,
        dateadd('minute', event_duration, event_start_datetime) as event_end_datetime,
        convert_timezone('UTC', event_start_datetime) as event_start_datetime_utc,
        dateadd('minute', event_duration, convert_timezone('UTC', event_start_datetime)) as event_end_datetime_utc,
        event_description,
        creation_date,
        block_source
    from timezone_logic

), dns_overlap as (
    /* Detect schedule blocks that overlap with any DNS (do-not-schedule) block for the same provider */
    select
        s1.schedule_block_skey,
        max(
            case
                when lower(s2.event_description) like '%dns%' then true
                else false
            end
        ) as is_do_not_schedule
    from keyed_blocks s1
    left join keyed_blocks s2
        on s1.physician_id = s2.physician_id
        and s1.event_start_datetime_utc >= s2.event_start_datetime_utc
        and s1.event_start_datetime_utc < s2.event_end_datetime_utc
    group by 1

), block_classification as (
    /* Classify block types and detect contiguity with next block */
    select
        kb.*,
        dns.is_do_not_schedule,

        -- block type flags
        lower(kb.event_description) like '%new patient%' as is_new_patient_slot,
        lower(kb.event_description) like '%established%' as is_established_slot,
        lower(kb.event_description) like '%toc%' as is_toc_slot,
        lower(kb.event_description) like '%same day%' as is_same_day_slot,
        lower(kb.event_description) like '%open scheduling%' as is_open_scheduling_slot,
        lower(kb.event_description) like '%dns-pmt%' as is_dns_admin_slot,

        -- a block is bookable if it is a recognized appointment type and not blocked by DNS
        (
            (lower(kb.event_description) like '%established%'
                or lower(kb.event_description) like '%toc%'
                or lower(kb.event_description) like '%same day%'
                or lower(kb.event_description) like '%new patient%'
                or lower(kb.event_description) like '%open scheduling%')
            and lower(kb.event_description) not like '%dns%'
            and dns.is_do_not_schedule = false
        ) as is_bookable,

        -- contiguity: does the next block for this provider on the same day start exactly when this one ends?
        lead(kb.event_start_datetime_utc) over (
            partition by kb.physician_id, kb.location_name, kb.event_date
            order by kb.event_start_datetime_utc
        ) as next_block_start_utc,

        lead(kb.schedule_block_skey) over (
            partition by kb.physician_id, kb.location_name, kb.event_date
            order by kb.event_start_datetime_utc
        ) as next_block_skey,

        /*
            Time-based flip rules: blocks designated for specific visit types
            become open to same-day/any scheduling before the appointment time.
            - TOC blocks: flip 24 hours before event start
            - Established blocks: flip 48 hours before event start
            - New Patient blocks: flip 48 hours before event start
        */
        case
            when lower(kb.event_description) like '%toc%'
                and kb.event_start_datetime_utc <= dateadd('hour', 24, current_timestamp())
                then true
            when (lower(kb.event_description) like '%established%' or lower(kb.event_description) like '%new patient%')
                and kb.event_start_datetime_utc <= dateadd('hour', 48, current_timestamp())
                then true
            else false
        end as is_within_flip_window

    from keyed_blocks kb
    left join dns_overlap dns using (schedule_block_skey)
)

select
    schedule_block_skey,
    location_name,
    provider_name,
    npi,
    specialty_desc,
    is_actively_seeing_patients,
    provider_type,
    location_state,
    physician_id,
    event_date,
    event_time,
    event_duration,
    event_start_datetime,
    event_end_datetime,
    event_start_datetime_utc,
    event_end_datetime_utc,
    event_description,
    creation_date,
    block_source,
    is_do_not_schedule,
    is_new_patient_slot,
    is_established_slot,
    is_toc_slot,
    is_same_day_slot,
    is_open_scheduling_slot,
    is_dns_admin_slot,
    is_bookable,
    is_within_flip_window,
    -- contiguity: true if the next block starts exactly when this one ends (same provider, same location, same day)
    (next_block_start_utc = event_end_datetime_utc) as has_contiguous_next_block,
    next_block_skey as contiguous_next_block_skey
from block_classification
qualify row_number() over (partition by schedule_block_skey order by block_source asc) = 1
    )
;


  