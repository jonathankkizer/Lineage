
  create or replace   view dw_dev.dev_jkizer.int_transportation_worklist
  
    
    
(
  
    "WORKLIST_STATUS" COMMENT $$$$, 
  
    "NEEDS_WHEELCHAIR" COMMENT $$$$, 
  
    "SUVIDA_ID" COMMENT $$$$, 
  
    "ELATION_ID" COMMENT $$$$, 
  
    "ELATION_PATIENT_URL" COMMENT $$$$, 
  
    "FULL_NAME" COMMENT $$$$, 
  
    "TEXT_OPT_IN" COMMENT $$$$, 
  
    "APPOINTMENT_TIME" COMMENT $$$$, 
  
    "APPOINTMENT_DATETIME_UTC" COMMENT $$$$, 
  
    "APPOINTMENT_LOCATION_NAME" COMMENT $$$$, 
  
    "APPOINTMENT_STATUS" COMMENT $$$$, 
  
    "APPOINTMENT_DESCRIPTION" COMMENT $$$$, 
  
    "APPOINTMENT_INSTRUCTIONS" COMMENT $$$$, 
  
    "APPOINTMENT_ID" COMMENT $$$$, 
  
    "APPOINTMENT_CREATOR_NAME" COMMENT $$$$, 
  
    "PLATFORM" COMMENT $$$$, 
  
    "TRIP_DATE" COMMENT $$$$, 
  
    "TRIP_PICKUP_TIME" COMMENT $$$$, 
  
    "TRIP_DROPOFF_TIME" COMMENT $$$$, 
  
    "TRIP_LOCATION" COMMENT $$$$, 
  
    "TRIP_DESTINATION_CATEGORY" COMMENT $$$$, 
  
    "TRANSPORTATION_DRIVER" COMMENT $$$$, 
  
    "PICKUP_ADDRESS" COMMENT $$$$, 
  
    "PICKUP_SITE_TYPE" COMMENT $$$$, 
  
    "DROPOFF_ADDRESS" COMMENT $$$$, 
  
    "DROPOFF_SITE_TYPE" COMMENT $$$$, 
  
    "TRANSPORTATION_SKEY" COMMENT $$$$, 
  
    "INTEGRATION_SKEY" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    -- get scheduled appts in Elation 
-- only filter for appts from patients with transportation needs through active tag list 
-- does the patient require mobility or wheelchair? 


-- of those appts, connect to momentm through suvida_id 
  -- date to appt date 
  -- ride time to appt time 
    -- ride needs to arrive at least 15 mins prior to appt time 
    -- ride needs to pick up at least 1 hour prior to appt time for pickup 
  -- ride location to clinic location
  


  with transpo_needed_appts as (
    select 
        iff(active_tag_list ilike ('%wheelchair%'), 1, 0) as needs_wheelchair,
        pa.suvida_id, 
        pa.elation_id, 
        ps.elation_patient_url,
        ps.full_name,
        case when ps.active_tag_list ilike ('%text opt%') then 1 else 0 end as text_opt_in,
        appointment_time,
        appointment_date as appointment_datetime_utc, 
        pa.appointment_location_name,
        appointment_status,
        appointment_description,
        appointment_instructions,
        cast(pa.appointment_id as string) as appointment_id,
        concat(appointment_creator_first_name, ' ', appointment_creator_last_name) as appointment_creator_name
    from dw_dev.dev_jkizer.patient_appointment pa
    inner join dw_dev.dev_jkizer.patient_summary ps 
        on ps.suvida_id = pa.suvida_id 
    where 
        appointment_status in ('confirmed', 'scheduled', 'cancelled') and 
        (lower(ps.active_tag_list) ilike ('%transportation insecurity%') or pa.appointment_description ilike ('%transpo%')) and 
        lower(visit_location_type) not like ('%virtual%') and 
        (lower(pa.appointment_instructions) not like ('%declined%') and lower(pa.appointment_instructions) not like ('%not needed%'))
        and date(appointment_datetime_utc) <= dateadd('month', 3, current_date())
),

final as (
select 
    case 
        when appointment_status = 'cancelled' and status != 'Canceled' then 'Cancel Transportation'
        when appointment_status = 'cancelled' and pt.suvida_id is null then 'No Change Needed'
        when appointment_location_name != trip_location then 'Fix Clinic Location'
        when appointment_status != 'cancelled' and (timediff(minute, trip_dropoff_time::time, appointment_time::time) < 15) then 'Fix Transportation Dropoff Time'
        when pt.suvida_id is null then 'Transportation Needed'
        else 'No Change Needed' 
    end as worklist_status,
    t.*,
    pt.platform,
    pt.trip_date,
    pt.trip_pickup_time,
    pt.trip_dropoff_time,
    trip_location,
    trip_destination_category,
    transportation_driver,
    pickup_address, 
    pickup_site_type, 
    dropoff_address, 
    dropoff_site_type,
    transportation_skey,
    md5(cast(coalesce(cast(t.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.appointment_datetime_utc as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(transportation_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(trip_pickup_time as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(trip_dropoff_time as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(trip_location as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_description as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(appointment_instructions as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey
from transpo_needed_appts t
left join dw_dev.dev_jkizer.patient_transportation pt 
-- we only want to track scheduled rides to the clinics, trips home are not as important 
    on pt.suvida_id = t.suvida_id 
    and pt.trip_date = date(appointment_datetime_utc) 
    and dropoff_site_type ilike ('%center%')
-- only look at appointments 1 weeks out
  where date(appointment_datetime_utc) between current_date() and dateadd('day', 7, current_date)
qualify row_number() over (partition by appointment_id order by trip_dropoff_time desc) = 1
order by appointment_datetime_utc desc
) 

select * from final where worklist_status != 'No Change Needed'
  );

