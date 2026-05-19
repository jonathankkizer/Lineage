
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_transportation_uber_trip
    copy grants
    
    
    as (--- The data we get from Uber rides has no direct link to Suvida patients... 
--- We can link an Uber ride to Suvida patient in 4 ways, from least effort to most effort:
--- 1. Direct linkage of first and last name, and phone number
--- 2. Use soundex function to link first and last name for possible misspelling 
--- 3. Link uber pickup/drop off address to patient's geocoding address
--- 4. Most costly, jarowinkler_similarity function compares similary between two strings and assigns a value. We only want > 85% similarity between first and last name for completed rides or rides > $20

with patients_w_geocoded_addresses as (
    select
        dp.suvida_id,
        dp.elation_id,
        dp.first_name,
        dp.last_name,
        dp.phone,
        dp.is_active_assignment,
        dp.creation_date,
        pa.freeform_address,
        -- Pre-compute normalized names for faster exact matching
        trim(lower(dp.first_name)) as first_name_norm,
        trim(lower(dp.last_name)) as last_name_norm,
        -- Create soundex for phonetic matching (cheaper than Jaro-Winkler)
        soundex(dp.first_name) as first_name_soundex,
        soundex(dp.last_name) as last_name_soundex
    from dw_dev.dev_jkizer.dim_patient dp
    left join dw_dev.dev_jkizer_staging.patient_addresses pa
        on dp.suvida_id = pa.suvida_id and
          lower(coalesce(dp.address_line_1, '')) = lower(pa.address_line_1_key) and
          lower(coalesce(dp.address_line_2, '')) = lower(coalesce(pa.address_line_2_key, '')) and
          lower(coalesce(dp.city, '')) = lower(pa.city_key) and
          lower(coalesce(dp.state, '')) = lower(pa.state_key) and
          lower(coalesce(dp.zip, '')) = lower(pa.zip_key) and
          pa.source = 'Google' and
          pa._idx = 1
),

trips_w_skey as (
    select
        md5(cast(coalesce(cast(trip_eats_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(transaction_timestamp_utc as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as trip_skey,
        *,
        -- Pre-normalize trip names too
        trim(lower(guest_first_name)) as guest_first_name_norm,
        trim(lower(guest_last_name)) as guest_last_name_norm,
        soundex(guest_first_name) as guest_first_name_soundex,
        soundex(guest_last_name) as guest_last_name_soundex,
        -- Clean phone number once
        ltrim(guest_phone_number, '1') as guest_phone_clean,
        row_number() over (partition by trip_eats_id, transaction_amount_in_usd_incl__taxes order by transaction_amount_in_usd_incl__taxes asc) as _adjustment_index
    from dw_dev.dev_jkizer_staging.stg_uber_trip
),

-- Step 1: Try exact matches first (fastest, cheapest)
exact_matches as (
    select 
        ub.trip_skey,
        ps.suvida_id,
        ps.elation_id,
        ps.is_active_assignment,
        ps.creation_date,
        guest_phone_clean,
        ps.phone,
        'exact_name' as match_type
    from trips_w_skey ub
    inner join patients_w_geocoded_addresses ps
        on ub.guest_first_name_norm = ps.first_name_norm
        and ub.guest_last_name_norm = ps.last_name_norm
        and ub.guest_phone_clean = ps.phone
),

-- Step 2: Soundex matches for remaining trips (cheaper fuzzy matching)
soundex_matches as (
    select 
        ub.trip_skey,
        ps.suvida_id,
        ps.elation_id,
        ps.is_active_assignment,
        ps.creation_date,
        guest_phone_clean,
        ps.phone,
        'soundex_name' as match_type
    from trips_w_skey ub
    inner join patients_w_geocoded_addresses ps
        on ub.guest_first_name_soundex = ps.first_name_soundex
        and ub.guest_last_name_soundex = ps.last_name_soundex
        and ub.guest_phone_clean = ps.phone
    where ub.trip_skey not in (select trip_skey from exact_matches)
),

-- Step 3: Address-based matches for remaining trips
address_matches as (
    select 
        ub.trip_skey,
        ps.suvida_id,
        ps.elation_id,
        ps.is_active_assignment,
        ps.creation_date,
        ub.guest_phone_clean,
        ps.phone,
        'address_match' as match_type
    from trips_w_skey ub
    inner join patients_w_geocoded_addresses ps
        on ps.freeform_address is not null
        and (
            ub.guest_phone_clean = ps.phone or 
            (ub.guest_first_name_soundex = ps.first_name_soundex and ub.guest_last_name_soundex = ps.last_name_soundex)
        )
        and (
            
    upper(ub.pickup_address) like '%' || upper(split_part(ps.freeform_address, ',', 1)) || '%'
    or upper(ps.freeform_address) like '%' || upper(split_part(ub.pickup_address, ',', 1)) || '%'
    or (
        regexp_substr(ub.pickup_address, '\\b\\d{5}(-\\d{4})?\\b') = regexp_substr(ps.freeform_address, '\\b\\d{5}(-\\d{4})?\\b')
        and regexp_substr(ub.pickup_address, '\\b\\d{5}(-\\d{4})?\\b') is not null
    )
 
            or 
    upper(ub.drop_off_address) like '%' || upper(split_part(ps.freeform_address, ',', 1)) || '%'
    or upper(ps.freeform_address) like '%' || upper(split_part(ub.drop_off_address, ',', 1)) || '%'
    or (
        regexp_substr(ub.drop_off_address, '\\b\\d{5}(-\\d{4})?\\b') = regexp_substr(ps.freeform_address, '\\b\\d{5}(-\\d{4})?\\b')
        and regexp_substr(ub.drop_off_address, '\\b\\d{5}(-\\d{4})?\\b') is not null
    )
 
        )
    where ub.trip_skey not in (select trip_skey from exact_matches)
      and ub.trip_skey not in (select trip_skey from soundex_matches)
),

-- Step 4: ONLY use Jaro-Winkler as last resort for high-value cases
fuzzy_matches as (
    select 
        ub.trip_skey,
        ps.suvida_id,
        ps.elation_id,
        ps.is_active_assignment,
        ps.creation_date,
        guest_phone_clean,
        ps.phone,
        'fuzzy_jw' as match_type
    from trips_w_skey ub
    inner join patients_w_geocoded_addresses ps
        on (
            jarowinkler_similarity(ub.guest_first_name, ps.first_name) > 85 and
            jarowinkler_similarity(ub.guest_last_name, ps.last_name) > 85
        ) 
        and (
            
    upper(ub.pickup_address) like '%' || upper(split_part(ps.freeform_address, ',', 1)) || '%'
    or upper(ps.freeform_address) like '%' || upper(split_part(ub.pickup_address, ',', 1)) || '%'
    or (
        regexp_substr(ub.pickup_address, '\\b\\d{5}(-\\d{4})?\\b') = regexp_substr(ps.freeform_address, '\\b\\d{5}(-\\d{4})?\\b')
        and regexp_substr(ub.pickup_address, '\\b\\d{5}(-\\d{4})?\\b') is not null
    )
 
            or 
    upper(ub.drop_off_address) like '%' || upper(split_part(ps.freeform_address, ',', 1)) || '%'
    or upper(ps.freeform_address) like '%' || upper(split_part(ub.drop_off_address, ',', 1)) || '%'
    or (
        regexp_substr(ub.drop_off_address, '\\b\\d{5}(-\\d{4})?\\b') = regexp_substr(ps.freeform_address, '\\b\\d{5}(-\\d{4})?\\b')
        and regexp_substr(ub.drop_off_address, '\\b\\d{5}(-\\d{4})?\\b') is not null
    )
 
            or (ub.guest_phone_clean = ps.phone)
        )
    where ub.trip_skey not in (select trip_skey from exact_matches)
      and ub.trip_skey not in (select trip_skey from soundex_matches)  
      and ub.trip_skey not in (select trip_skey from address_matches)
      -- Only run fuzzy matching on completed trips or high-value transactions
      and (lower(ub.ride_status) = 'completed')
      
      --or abs(ub.transaction_amount_in_usd_incl__taxes) > 20)
),

-- Combine all matches with priority
all_matches as (
    select * from exact_matches
    union all
    select * from soundex_matches  
    union all
    select * from address_matches
    union all
    select * from fuzzy_matches
),

trips_w_patients as (
    select
        ub.trip_skey,
        ub.trip_eats_id as trip_id,
        coalesce(am.suvida_id, null) as suvida_id,
        coalesce(am.elation_id, null) as elation_id,
        ub.guest_first_name as first_name,
        ub.guest_last_name as last_name,
        'Uber' as platform,
        ub.guest_phone_clean,
        phone,
        ub.transaction_timestamp_utc as trip_created_date,
        to_date(ub.transaction_timestamp_utc) as trip_date,
        null as lead_days,
        ub.program as purpose,
        ub.email as created_by,
        'Uber' as service_type,
        'Uber' as driver,
        lower(ub.ride_status) as status,
        case when lower(ub.ride_status) = 'completed' then 1 else 0 end as is_completed_trip,
        case when lower(ub.ride_status) = 'completed' and (ub._adjustment_index = 1 and ub.transaction_amount_in_local_currency_incl__taxes < 0) then 1 else 0 end as is_adjustment_trip,
        0 as is_unfulfilled_trip,
        case when lower(ub.ride_status) = 'canceled' then 1 else 0 end as is_cancelled_trip,
        case when lower(ub.ride_status) = 'driver_canceled' then 1 else 0 end as is_no_show_trip,
        iff(am.suvida_id is not null, 1, 0) as is_suvida_patient,
        to_time(iff(ub.pickup_time_local = '--', null, ub.pickup_time_local)) as pickup_time,
        iff(map.location_id is not null, lp.location_name, '') as pickup_site_name,
        iff(map.location_id is not null, 'Center', 'Home/Other') as pickup_site_type,
        ub.pickup_address,
        to_time(iff(ub.drop_off_time_local = '--', null, ub.drop_off_time_local)) as dropoff_time,
        iff(mad.location_id is not null, ld.location_name, '') as dropoff_site_name,
        iff(mad.location_id is not null, 'Center', 'Home/Other') as dropoff_site_type,
        ub.drop_off_address as dropoff_address,
        ub.distance_mi as mileage,
        ub.transaction_amount_in_usd_incl__taxes as fare,
        iff(lower(trim(ub.first_name)) = 'momentm' and lower(trim(ub.last_name)) = 'admin', 1, 0) as is_momentm_trip,
        coalesce(am.match_type, 'no_match') as match_method,
        row_number() over (partition by ub.trip_skey order by is_active_assignment desc, creation_date desc) as _idx
    from trips_w_skey ub
    left join all_matches am on ub.trip_skey = am.trip_skey
    left join dw_dev.dev_jkizer_source.map_momentm_site_address map
        on split_part(ub.pickup_address, ',', 0) = map.address
    left join dw_dev.dev_jkizer.dim_location lp
        on map.location_id = lp.location_id
    left join dw_dev.dev_jkizer_source.map_momentm_site_address mad
        on split_part(ub.drop_off_address, ',', 0) = mad.address
    left join dw_dev.dev_jkizer.dim_location ld
        on mad.location_id = ld.location_id
)

select
    trip_skey,
    trip_id,
    suvida_id,
    elation_id,
    first_name,
    last_name,
    guest_phone_clean,
    phone,
    platform,
    trip_created_date,
    trip_date,
    lead_days,
    purpose,
    created_by,
    service_type,
    driver,
    status,
    is_completed_trip,
    is_adjustment_trip,
    is_unfulfilled_trip,
    is_cancelled_trip,
    is_no_show_trip,
    is_suvida_patient,
    pickup_time,
    pickup_site_name,
    pickup_site_type,
    pickup_address,
    dropoff_time,
    dropoff_site_name,
    dropoff_site_type,
    dropoff_address,
    mileage,
    fare,
    is_momentm_trip,
    match_method  -- Added for debugging/monitoring
from trips_w_patients twp
where _idx = 1
    )
;


  