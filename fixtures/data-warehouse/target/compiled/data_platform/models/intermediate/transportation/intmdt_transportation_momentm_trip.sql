with trips as (
    select
        booking_id as trip_id,
        suvida_id,
        tr.elation_id,
        tr.first_name,
        tr.last_name,
        'Momentm' as platform,
        created_date as trip_created_date,
        to_date(trip_date) as trip_date,
        datediff(day, to_date(trip_created_date), trip_date) as lead_days,
        purpose,
        service_type,
        case
            when run_name = 'Uber' then 'Uber'
            when run_name = 'Uber Integration' then 'Uber'
            else driver
        end as driver,
        schedule_status_description as status,
        case
            when schedule_status = 10 then 1
            when schedule_status = 20 then 1
            when schedule_status = 30 then 1
            else 0        
        end as is_completed_trip,
        iff(schedule_status = 0, 1, 0) as is_unfulfilled_trip,
        iff(schedule_status_category = 'cancellation', 1, 0) as is_cancelled_trip,
        iff(schedule_status_category = 'no show', 1, 0) as is_no_show_trip,
        iff(siw.suvida_id is not null, 1, 0) as is_suvida_patient,
        pickup_time,
        iff(map.location_id is not null, lp.location_name, '') as pickup_site_name,
        iff(map.location_id is not null, 'Center', 'Home/Other') as pickup_site_type,
        concat(pickup_address, ', ', pickup_city, ', ', pickup_state, ' ', pickup_zip) as pickup_address,
        dropoff_time,
        iff(mad.location_id is not null, ld.location_name, '') as dropoff_site_name,
        iff(mad.location_id is not null, 'Center', 'Home/Other') as dropoff_site_type,
        concat(dropoff_address, ', ', dropoff_city, ', ', dropoff_state, ' ', dropoff_zip) as dropoff_address,
        mileage,
        null as fare
    from dw_dev.dev_jkizer_staging.stg_momentm_trip tr
    left join dw_dev.dev_jkizer.suvida_id_walk siw 
        on tr.elation_id = siw.member_id 
        and siw.source = 'Elation'
    left join dw_dev.dev_jkizer_source.map_momentm_site_address map
        on tr.pickup_address = map.address
    left join dw_dev.dev_jkizer.dim_location lp
        on map.location_id = lp.location_id
    left join dw_dev.dev_jkizer_source.map_momentm_site_address mad
        on tr.dropoff_address = mad.address
    left join dw_dev.dev_jkizer.dim_location ld
        on mad.location_id = ld.location_id
)

select
    md5(cast(coalesce(cast(trip_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as trip_skey,
    *,
    case
        when is_completed_trip <> 1 then null
        when coalesce(pickup_time, '') = '' then null
        when coalesce(dropoff_time, '') = '' then null
        else datediff(minute, pickup_time::TIME, dropoff_time::TIME)
    end as elapsed_time_minutes
from trips