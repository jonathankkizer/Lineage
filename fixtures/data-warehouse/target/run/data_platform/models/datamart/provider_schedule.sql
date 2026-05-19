
  
    

create or replace transient table dw_dev.dev_jkizer.provider_schedule
    copy grants
    
    
    as (/*
    Datamart: Provider schedule with appointment fill, compliance, and availability flags.

    Grain: One row per schedule block (schedule_block_skey).
    Designed for Lightdash — all aggregation handled via yml metric definitions.

    Key improvements over prior version:
    - Full overlap detection (handles appointments spanning entire blocks)
    - Schedule compliance flag (appointment type matches slot type)
    - Explicit is_bookable flag (denominator for utilization excludes DNS/admin)
    - Contiguity-aware open hour block detection (blocks must be on same day, same location, truly consecutive)
*/

with block_appointments as (
    /* Aggregate appointment matches per schedule block */
    select
        schedule_block_skey,
        count(distinct appointment_skey) as num_appointments_in_block,
        listagg(distinct appointment_skey, ' | ') as appointment_skeys_in_block,
        max(case when is_type_compliant then 1 else 0 end) as has_compliant_appointment,
        min(case when is_type_compliant then 1 else 0 end) as all_appointments_compliant,
        count(case when not is_type_compliant then 1 end) as num_noncompliant_appointments
    from dw_dev.dev_jkizer.fct_schedule_block_appointment
    group by 1

), schedule_with_appointments as (
    select
        sb.*,
        coalesce(ba.num_appointments_in_block, 0) as num_appointments_in_block,
        ba.appointment_skeys_in_block,

        -- a block is open if it is bookable and has no appointments
        sb.is_bookable and coalesce(ba.num_appointments_in_block, 0) = 0 as is_open,

        -- compliance: only meaningful for blocks that have appointments
        case
            when coalesce(ba.num_appointments_in_block, 0) = 0 then null
            when ba.all_appointments_compliant = 1 then true
            else false
        end as is_type_compliant,
        coalesce(ba.num_noncompliant_appointments, 0) as num_noncompliant_appointments

    from dw_dev.dev_jkizer.fct_schedule_block sb
    left join block_appointments ba using (schedule_block_skey)

), with_open_hour_block as (
    select
        sa.*,

        /* Open hour block: two consecutive 30-minute bookable blocks, both open,
           on the same day at the same location, where the next block starts exactly
           when this one ends */
        case
            when sa.is_open
            and sa.event_duration = 30
            and sa.has_contiguous_next_block
            -- check that the next contiguous block is also open and 30 minutes
            and exists (
                select 1
                from schedule_with_appointments sa2
                where sa2.schedule_block_skey = sa.contiguous_next_block_skey
                and sa2.is_open
                and sa2.event_duration = 30
            )
            then true
            else false
        end as is_open_hour_block

    from schedule_with_appointments sa
)

select
    schedule_block_skey,
    location_name,
    provider_name,
    npi,
    specialty_desc,
    is_actively_seeing_patients,
    provider_type,
    physician_id,
    event_date,
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
    is_open,
    is_within_flip_window,
    -- block is open AND within the flip window (available for same-day/flexible scheduling)
    is_open and is_within_flip_window as is_open_and_flipped,
    is_type_compliant,
    num_noncompliant_appointments,
    is_open_hour_block,
    num_appointments_in_block,
    appointment_skeys_in_block
from with_open_hour_block
    )
;


  