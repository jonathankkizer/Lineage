
  
    

create or replace transient table dw_dev.dev_jkizer.fct_schedule_block_appointment
    copy grants
    
    
    as (/*
    Bridge fact: Links appointments to the schedule blocks they occupy.

    Handles:
    - Appointment starts within block
    - Appointment ends within block
    - Appointment spans the entire block (starts before and ends after)
    - Location matching via provider (schedule blocks are location-specific through dim_provider)

    Does NOT use a native Elation FK (recurring_event_schedule is unavailable in the hosted DB).
    Uses time-overlap matching. The match_method column future-proofs for switching to a native link.

    Compliance uses map_schedule_block_appointment_type seed to determine whether the appointment
    type is explicitly allowed in the block type. Falls back to visit_level matching for
    provider categories not yet in the seed (non-PCP).

    Grain: One row per (schedule_block_skey × appointment_skey)
*/

with block_appointment_matches as (
    select
        sb.schedule_block_skey,
        sb.is_new_patient_slot,
        sb.is_established_slot,
        sb.is_toc_slot,
        sb.is_same_day_slot,
        sb.is_open_scheduling_slot,
        fa.appointment_skey,
        fa.appointment_type,
        fa.visit_level,
        fa.appointment_provider_category,
        fa.appointment_status,
        'time_overlap' as match_method
    from dw_dev.dev_jkizer.fct_schedule_block sb
    inner join dw_dev.dev_jkizer.fct_appointment fa
        on sb.physician_id = fa.physician_id
        and fa.appointment_status not in ('cancelled', 'notSeen')
        /* Full overlap detection: appointment overlaps block if appointment starts before block ends
           AND appointment ends after block starts. This covers all cases:
           - appointment starts within block
           - appointment ends within block
           - appointment spans the entire block */
        and fa.appointment_datetime_utc < sb.event_end_datetime_utc
        and dateadd(minute, fa.appointment_duration, fa.appointment_datetime_utc) > sb.event_start_datetime_utc

), compliance_check as (
    select
        bam.schedule_block_skey,
        bam.appointment_skey,
        bam.match_method,
        bam.appointment_type,
        bam.visit_level,
        bam.appointment_provider_category,
        bam.appointment_status,

        /*
            Schedule compliance: Is this appointment type explicitly allowed in this block type?

            Uses the map_schedule_block_appointment_type seed for explicit block_type → appointment_type
            mappings (currently PCP). Falls back to visit_level matching for provider categories
            not yet in the seed.

            The seed is normalized: "Established, Same Day" in source data becomes two rows
            (Established → appt_type, Same Day → appt_type), so we check if any of the
            block's type flags match a seed entry for this appointment_type.
        */
        case
            -- open scheduling blocks accept any appointment type
            when bam.is_open_scheduling_slot then true

            -- explicit seed match: check if the appointment_type appears in the seed
            -- for any block_type that matches this block's flags
            when exists (
                select 1
                from dw_dev.dev_jkizer_source.map_schedule_block_appointment_type m
                where m.appointment_type = bam.appointment_type
                and (
                    (m.block_type = 'Established' and bam.is_established_slot)
                    or (m.block_type = 'New Patient' and bam.is_new_patient_slot)
                    or (m.block_type = 'TOC' and bam.is_toc_slot)
                    or (m.block_type = 'Same Day' and bam.is_same_day_slot)
                )
            ) then true

            -- fallback for provider categories not in the seed: use visit_level matching
            when not exists (
                select 1
                from dw_dev.dev_jkizer_source.map_schedule_block_appointment_type m
                where m.appointment_type = bam.appointment_type
            ) then
                case
                    when bam.is_new_patient_slot and bam.visit_level = 'New' then true
                    when bam.is_established_slot and bam.visit_level = 'Established' then true
                    when bam.is_toc_slot and bam.visit_level = 'TOC' then true
                    when bam.is_same_day_slot then true
                    else false
                end

            -- appointment_type is in the seed but doesn't match any of this block's types
            else false
        end as is_type_compliant,

        -- flag whether the compliance check used the seed or the fallback
        exists (
            select 1
            from dw_dev.dev_jkizer_source.map_schedule_block_appointment_type m
            where m.appointment_type = bam.appointment_type
        ) as is_seed_mapped

    from block_appointment_matches bam
)

select
    schedule_block_skey,
    appointment_skey,
    match_method,
    is_type_compliant,
    is_seed_mapped,
    appointment_type,
    visit_level,
    appointment_provider_category,
    appointment_status
from compliance_check
    )
;


  