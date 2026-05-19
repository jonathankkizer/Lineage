with joined_trips as (
    select 
        coalesce(u.trip_skey, m.trip_skey) as transportation_skey,
        coalesce(u.suvida_id, m.suvida_id) as suvida_id,
        coalesce(u.elation_id, m.elation_id) as elation_id,
        coalesce(u.first_name, m.first_name) as first_name,
        coalesce(u.last_name, m.last_name) as last_name,
        case
            when u.platform is not null and m.platform is not null then 'Momentm/Uber'
            else coalesce(u.platform, m.platform)
        end as platform,
        coalesce(u.trip_created_date, m.trip_created_date) as trip_created_date,
        coalesce(u.pickup_time, m.pickup_time) as trip_pickup_time,
        coalesce(u.dropoff_time, m.dropoff_time) as trip_dropoff_time,
        coalesce(u.trip_date, m.trip_date) as trip_date,
        coalesce(m.lead_days, u.lead_days) as lead_days,
        coalesce(u.purpose, m.purpose) as purpose,
        coalesce(u.service_type, m.service_type) as transportation_service,
        coalesce(u.driver, m.driver) as transportation_driver,        
        coalesce(u.status, m.status) as status,
        coalesce(u.is_completed_trip, m.is_completed_trip) as is_completed_trip,
        u.is_adjustment_trip,
        coalesce(u.is_unfulfilled_trip, m.is_unfulfilled_trip) as is_unfulfilled_trip,
        coalesce(u.is_cancelled_trip, m.is_cancelled_trip) as is_cancelled_trip,
        coalesce(u.is_no_show_trip, m.is_no_show_trip) as is_no_show_trip,
        coalesce(u.is_suvida_patient, m.is_suvida_patient) as is_suvida_patient,
        coalesce(u.pickup_address, m.pickup_address) as pickup_address,
        coalesce(u.pickup_site_name, m.pickup_site_name) as pickup_site_name,
        coalesce(u.pickup_site_type, m.pickup_site_type) as pickup_site_type,
        coalesce(u.dropoff_address, m.dropoff_address) as dropoff_address,
        coalesce(u.dropoff_site_name, m.dropoff_site_name) as dropoff_site_name,
        coalesce(u.dropoff_site_type, m.dropoff_site_type) as dropoff_site_type,
        coalesce(u.mileage, m.mileage) as mileage,
        u.fare
    from dw_dev.dev_jkizer.intmdt_transportation_momentm_trip m
    full outer join dw_dev.dev_jkizer.intmdt_transportation_uber_trip u
        on m.suvida_id = u.suvida_id and
           u.is_momentm_trip = 1 and
           m.trip_date = u.trip_date and
           m.pickup_site_type = u.pickup_site_type and
           m.dropoff_site_type = u.dropoff_site_type and
           m.is_completed_trip = u.is_completed_trip and
           m.is_cancelled_trip = u.is_cancelled_trip and
           m.is_unfulfilled_trip = u.is_unfulfilled_trip and
           m.is_no_show_trip = u.is_no_show_trip
),

transportation_insecure_patients as (
    select distinct suvida_id
    from dw_dev.dev_jkizer.fct_patient_tag
    where
        is_active_tag = TRUE and
        lower(tag_value) like 'transportation%'
),

transportation_insecure_joined_trips as (
    select 
        transportation_skey,
        jt.suvida_id,
        elation_id,
        first_name,
        last_name,
        platform,
        trip_created_date,
        trip_date,
        to_number(lead_days) as lead_days,
        case
            when pickup_site_type = 'Center' and dropoff_site_type <> 'Center' then pickup_site_name
            when pickup_site_type <> 'Center' and dropoff_site_type = 'Center' then dropoff_site_name
            when pickup_site_type = 'Center' and dropoff_site_type = 'Center' then pickup_site_name
            else 'Home/Other'
        end as trip_location,
        concat('From ', pickup_site_type, ' to ', dropoff_site_type) as trip_destination_category,
        transportation_service,
        transportation_driver,
        status,
        trip_pickup_time,
        trip_dropoff_time,
        is_completed_trip,
        is_adjustment_trip,
        is_unfulfilled_trip,
        is_cancelled_trip,
        is_no_show_trip,
        is_suvida_patient,
        iff(tip.suvida_id is null, FALSE, TRUE) as has_transportation_insecurity,
        pickup_address,
        pickup_site_type,
        dropoff_address,
        dropoff_site_type,
        mileage,
        fare,
        row_number() over (partition by transportation_skey order by (select null)) as _idx
    from joined_trips jt
    left join transportation_insecure_patients tip
        on jt.suvida_id = tip.suvida_id
),

single_entries as (
    select 
        transportation_skey,
        max(_idx) max_idx
    from transportation_insecure_joined_trips
    group by all
),

deduplicated_entries as (
    select 
        coalesce(u.trip_skey, m.trip_skey) as transportation_skey,
        coalesce(u.suvida_id, m.suvida_id) as suvida_id,
        coalesce(u.elation_id, m.elation_id) as elation_id,
        coalesce(u.first_name, m.first_name) as first_name,
        coalesce(u.last_name, m.last_name) as last_name,
        case
            when u.platform is not null and m.platform is not null then 'Momentm/Uber'
            else coalesce(u.platform, m.platform)
        end as platform,
        coalesce(u.trip_created_date, m.trip_created_date) as trip_created_date,
        coalesce(u.pickup_time, m.pickup_time) as trip_pickup_time,
        coalesce(u.dropoff_time, m.dropoff_time) as trip_dropoff_time,
        coalesce(u.trip_date, m.trip_date) as trip_date,
        coalesce(m.lead_days, u.lead_days) as lead_days,
        coalesce(u.purpose, m.purpose) as purpose,
        coalesce(u.service_type, m.service_type) as transportation_service,
        coalesce(u.driver, m.driver) as transportation_driver,        
        coalesce(u.status, m.status) as status,
        coalesce(u.is_completed_trip, m.is_completed_trip) as is_completed_trip,
        u.is_adjustment_trip,
        coalesce(u.is_unfulfilled_trip, m.is_unfulfilled_trip) as is_unfulfilled_trip,
        coalesce(u.is_cancelled_trip, m.is_cancelled_trip) as is_cancelled_trip,
        coalesce(u.is_no_show_trip, m.is_no_show_trip) as is_no_show_trip,
        coalesce(u.is_suvida_patient, m.is_suvida_patient) as is_suvida_patient,
        coalesce(u.pickup_address, m.pickup_address) as pickup_address,
        coalesce(u.pickup_site_name, m.pickup_site_name) as pickup_site_name,
        coalesce(u.pickup_site_type, m.pickup_site_type) as pickup_site_type,
        coalesce(u.dropoff_address, m.dropoff_address) as dropoff_address,
        coalesce(u.dropoff_site_name, m.dropoff_site_name) as dropoff_site_name,
        coalesce(u.dropoff_site_type, m.dropoff_site_type) as dropoff_site_type,
        coalesce(u.mileage, m.mileage) as mileage,
        coalesce(u.fare, m.fare) as fare
    from dw_dev.dev_jkizer.intmdt_transportation_momentm_trip m
    full outer join dw_dev.dev_jkizer.intmdt_transportation_uber_trip u
        on m.suvida_id = u.suvida_id and
            u.is_momentm_trip = 1 and
            m.trip_date = u.trip_date and
            m.pickup_site_type = u.pickup_site_type and
            m.dropoff_site_type = u.dropoff_site_type and
            m.is_completed_trip = u.is_completed_trip and
            m.is_cancelled_trip = u.is_cancelled_trip and
            m.is_unfulfilled_trip = u.is_unfulfilled_trip and
            m.is_no_show_trip = u.is_no_show_trip and
            jarowinkler_similarity(u.pickup_address, m.pickup_address) >= 88 and
            jarowinkler_similarity(u.dropoff_address, m.dropoff_address) >= 88
    where
        coalesce(u.trip_skey, m.trip_skey) not in (
            select transportation_skey
            from single_entries
            where max_idx = 1
        )
)

select
    transportation_skey,
    suvida_id,
    elation_id,
    first_name,
    last_name,
    platform,
    trip_created_date,
    trip_date,
    trip_pickup_time,
    trip_dropoff_time,
    lead_days,
    trip_location,
    trip_destination_category,
    transportation_service,
    transportation_driver,
    status,
    is_completed_trip,
    is_adjustment_trip,
    is_unfulfilled_trip,
    is_cancelled_trip,
    is_no_show_trip,
    is_suvida_patient,
    has_transportation_insecurity,
    pickup_address,
    pickup_site_type,
    dropoff_address,
    dropoff_site_type,
    mileage,
    fare
from transportation_insecure_joined_trips
where transportation_skey in (
    select transportation_skey
    from single_entries
    where max_idx = 1
)

union all

select 
    transportation_skey,
    de.suvida_id,
    elation_id,
    first_name,
    last_name,
    platform,
    trip_created_date,
    trip_date,
    trip_pickup_time,
    trip_dropoff_time,
    to_number(lead_days) as lead_days,
    case
        when pickup_site_type = 'Center' and dropoff_site_type <> 'Center' then pickup_site_name
        when pickup_site_type <> 'Center' and dropoff_site_type = 'Center' then dropoff_site_name
        when pickup_site_type = 'Center' and dropoff_site_type = 'Center' then pickup_site_name
        else 'Home/Other'
    end as trip_location,
    concat('From ', pickup_site_type, ' to ', dropoff_site_type) as trip_destination_category,
    transportation_service,
    transportation_driver,
    status,
    is_completed_trip,
    is_adjustment_trip,
    is_unfulfilled_trip,
    is_cancelled_trip,
    is_no_show_trip,
    is_suvida_patient,
    iff(tip.suvida_id is null, FALSE, TRUE) as has_transportation_insecurity,
    pickup_address,
    pickup_site_type,
    dropoff_address,
    dropoff_site_type,
    mileage,
    fare
from deduplicated_entries de
left join transportation_insecure_patients tip
    on de.suvida_id = tip.suvida_id