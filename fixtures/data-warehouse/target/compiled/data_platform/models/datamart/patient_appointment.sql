with encounter_data as (
    select distinct
        appointment_encounter_skey
    from dw_dev.dev_jkizer.fct_encounter
), appt_check_in_data as (
    select
        appointment_id,
        max(status_creation_datetime) as checked_in_datetime,
        max(status_creation_datetime_utc) as checked_in_datetime_utc
    from dw_dev.dev_jkizer.fct_appointment_status fas
    where fas.appointment_status = 'checkedIn'
    group by appointment_id
), cancelled_appts as (
    select *
    from dw_dev.dev_jkizer.fct_appointment
    where lower(appointment_status) = 'cancelled'
), no_show_appts as (
    select *
    from dw_dev.dev_jkizer.fct_appointment
    where lower(appointment_status) = 'notseen'
), scheduled_appts as (
    select 
        fa.appointment_id,
        fa.suvida_id,
        fa.appointment_datetime,
        fa.appointment_type_category,
        fas.status_creation_datetime,
        fas.status_creation_datetime_utc
    from dw_dev.dev_jkizer.fct_appointment_status fas
    join dw_dev.dev_jkizer.fct_appointment fa
        on fas.appointment_id = fa.appointment_id
    where lower(fas.appointment_status) = 'scheduled'
), no_show_reschedules as (
    select 
        ns.appointment_id as no_show_appt_id,
        vs.appointment_id as rescheduled_appt_id,
        vs.appointment_datetime as rescheduled_datetime,
        vs.status_creation_datetime
    from no_show_appts ns
    join scheduled_appts vs
        on ns.suvida_id = vs.suvida_id
       and vs.appointment_datetime > ns.appointment_datetime
       and date(vs.status_creation_datetime) <= dateadd(day, 5, ns.appointment_date)
       and vs.appointment_type_category = ns.appointment_type_category
       qualify ROW_NUMBER() over (partition by ns.appointment_id order by vs.appointment_datetime ) = 1
), no_show_status_flag as (
    select 
        ns.appointment_id,
        r.status_creation_datetime,
        case 
            when r.rescheduled_datetime is not null then true
            else false
        end as no_show_with_reschedule
    from no_show_appts ns
    left join no_show_reschedules r
        on ns.appointment_id = r.no_show_appt_id
), cancelled_reschedules as (
    select 
        ca.appointment_id as cancelled_appt_id,
        vs.appointment_id as rescheduled_appt_id,
        vs.appointment_datetime as rescheduled_datetime,
        vs.status_creation_datetime
    from cancelled_appts ca
    join scheduled_appts vs
        on ca.suvida_id = vs.suvida_id
       and vs.appointment_datetime > ca.appointment_datetime
       and ca.appointment_type_category = vs.appointment_type_category
       and date(vs.status_creation_datetime) <= dateadd(day, 5, ca.appointment_date)
       qualify ROW_NUMBER() over (partition by ca.appointment_id order by vs.appointment_datetime ) = 1
), cancelled_status_flag as (
    select 
        ca.appointment_id,
        r.status_creation_datetime,
        case 
            when r.rescheduled_datetime is not null then true
            else false
        end as cancelled_with_reschedule
    from cancelled_appts ca
    left join cancelled_reschedules r
        on ca.appointment_id = r.cancelled_appt_id
)
select
    fa.appointment_skey,
    fa.appointment_encounter_skey,
    fa.suvida_id,
    fa.elation_id,
    fa.appointment_id,
    fa.appointment_date,
    to_varchar(fa.appointment_time) as appointment_time,
    to_varchar(fa.appointment_time_utc) as appointment_time_utc,
    fa.appointment_datetime,
    acid.checked_in_datetime,
    fa.appointment_datetime_utc,
    acid.checked_in_datetime_utc,
    timestampdiff(minute, fa.appointment_datetime, acid.checked_in_datetime) as checked_in_appt_time_diff_minutes,
    fa.physician_id,
    fa.appointment_provider_name,
    fa.appointment_provider_first_name,
    fa.appointment_provider_last_name,
    fa.appointment_location_name,
    fa.appointment_type_category,
    fa.appointment_provider_category,
    fa.visit_level,
    fa.visit_location_type,
    fa.appointment_type,
    fa.appointment_description,
    fa.appointment_instructions,
    fa.appointment_duration,
    fa.appointment_status,
    fa.appointment_completed_ind,
    iff(ed.appointment_encounter_skey is null, 0, 1) as encounter_match_ind,
    fa.created_by_user_id,
    fa.appointment_creator_email,
    fa.appointment_creator_first_name,
    fa.appointment_creator_last_name,
    fa.creation_date,
    fa.creation_datetime,
    fa.last_modified_date,
    fa.last_modified_datetime,
    fa.deletion_datetime,
    fa.is_pcp_appt,
    fa.is_mh_appt,
    fa.is_nutrition_appt,
    fa.is_pharmacy_appt,
    fa.is_guia_appt,
    fa.is_virtual_appt,
    fa.is_pt_appt,
    fa.is_ma_appt,
    fa.is_provider_name_match,
    case 
        when timestampdiff(hour, fa.creation_datetime, fa.appointment_datetime) <= 8 
             and fa.creation_datetime < fa.appointment_datetime then true
        else false 
    end as is_same_day_pre_booking,
    case 
        when timestampdiff(hour, fa.creation_datetime, fa.appointment_datetime) <= 8 
             and fa.creation_datetime < fa.appointment_datetime 
             and fa.visit_level = 'Established' then true 
        else false 
    end as is_same_day_pre_booking_established,
    case 
        when timestampdiff(hour, fa.creation_datetime, fa.appointment_datetime) <= 8 
             and fa.creation_datetime < fa.appointment_datetime 
             and fa.visit_level = 'New' then true 
        else false 
    end as is_same_day_pre_booking_new,
    case 
        when timestampdiff(hour, fa.appointment_datetime, fa.creation_datetime) <= 8 
             and fa.creation_datetime > fa.appointment_datetime then true 
        else false 
    end as is_same_day_post_booking,
    nsf.no_show_with_reschedule,
	csf.cancelled_with_reschedule,
    csf.status_creation_datetime as cancelled_reschedule_creation_datetime
from dw_dev.dev_jkizer.fct_appointment fa
left join encounter_data ed 
    using (appointment_encounter_skey)
left join appt_check_in_data acid 
    using (appointment_id)
left join no_show_status_flag nsf 
    using (appointment_id)
left join cancelled_status_flag csf
	using (appointment_id)