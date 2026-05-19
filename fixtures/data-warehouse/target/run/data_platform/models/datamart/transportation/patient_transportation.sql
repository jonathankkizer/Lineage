
  
    

create or replace transient table dw_dev.dev_jkizer.patient_transportation
    copy grants
    
    
    as (select
    transportation_skey,
    suvida_id,
    elation_id,
    first_name,
    last_name,
    platform,
    trip_created_date as created_date,
    trip_date,
    trip_pickup_time,
    trip_dropoff_time,
    trip_location,
    trip_destination_category,
    transportation_service,
    transportation_driver,
    case
        when is_completed_trip = 1 and is_adjustment_trip = 0 then 'Completed'
        when is_adjustment_trip = 1 then 'Adjustment'
        when is_unfulfilled_trip = 1 then 'Unfulfilled'
        when is_cancelled_trip = 1 then 'Canceled'
        when is_no_show_trip = 1 then 'No Show'
    end as status,
    iff(is_completed_trip = 1, null, status) as extended_status,
    is_suvida_patient,
    has_transportation_insecurity,
    pickup_address,
    pickup_site_type,
    dropoff_address,
    dropoff_site_type,
    mileage,
    fare
from dw_dev.dev_jkizer.fct_transportation
    )
;


  