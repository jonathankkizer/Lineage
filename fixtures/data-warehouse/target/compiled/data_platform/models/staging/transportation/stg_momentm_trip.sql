with combined_trips as (
    -- Union raw data first, before expensive operations
    select *, 'NEW' as source_type
    from source_prod.momentm.trip_2025_1
    
    union all
    
    select *, 'OLD' as source_type
    from source_prod.momentm.trip
),

filtered_trips as (
    select distinct *
    from combined_trips
    where
        -- Filter early to reduce data volume
        not (
            lower(first_name) like any ('%test', '%testing', '%test-%') or
            lower(first_name) = 'manifest' or
            lower(last_name) like any ('%test', '%test-%', '%testing') or
            lower(mrn) like '%test%'
        )
    qualify row_number() over (partition by booking_id order by 
        case when source_type = 'NEW' then SRC_FILE_NAME end desc nulls last,
        case when source_type = 'OLD' then 1 else 0 end
    ) = 1
)

select
    BOOKING_ID,
    ITINERARY_ID,
    BOOKINGSEGMENT as SEGMENT,
    case 
        when source_type = 'NEW' 
        then TO_TIMESTAMP(BOOKEDDATE, 'YYYY/MM/DD, HH24:MI:SS')
        else BOOKEDDATE 
    end as CREATED_DATE,
    BOOKEDBY as CREATED_BY,
    MRN as ELATION_ID,
    PROVIDER_NAME,
    TRIPDATE as TRIP_DATE,
    PURPOSE,
    SERVICETYPE as SERVICE_TYPE,
    SCHEDULE_STATUS,
    ms.STATUS_DESCRIPTION as SCHEDULE_STATUS_DESCRIPTION,
    ms.STATUS_CATEGORY as SCHEDULE_STATUS_CATEGORY,
    ARRAY_AGG(MODEDESCRIPTION) as MODES,
    FIRST_NAME,
    LAST_NAME,
    MIDDLEINITIAL as MIDDLE_INITIAL,
    DRIVER,
    DRIVER_LICENSE_NUMBER,
    VEHICLE_NUMBER,
    VIN,
    LICENSE_NUMBER,
    RUN_NAME,
    PICKUPSITENAME as PICKUP_SITE_NAME,
    PICKUPADDRESS as PICKUP_ADDRESS,
    PICKUPADDRESSLINE1 as PICKUP_ADDRESS_LINE_1,
    PICKUPCITY as PICKUP_CITY,
    PICKUPSTATE as PICKUP_STATE,
    PICKUPZIP as PICKUP_ZIP,
    PICKUPPHONE as PICKUP_PHONE,
    DROPOFFSITENAME as DROPOFF_SITE_NAME,
    DROPOFFADDRESS as DROPOFF_ADDRESS,
    DROPOFFADDRESSLINE1 as DROPOFF_ADDRESS_LINE_1,
    DROPOFFCITY as DROPOFF_CITY,
    DROPOFFSTATE as DROPOFF_STATE,
    DROPOFFZIP as DROPOFF_ZIP,
    DROPOFFPHONE as DROPOFF_PHONE,
    PICKUP_TIME,
    DROPOFFTIME as DROPOFF_TIME,
    BOOKING_COMMENTS,
    PICKUPCOMMENTS as PICKUP_COMMENTS,
    DROPOFFCOMMENTS as DROPOFF_COMMENTS,
    MILEAGE,
    SRC_FILE_NAME,
	source_type
from filtered_trips ft
left join dw_dev.dev_jkizer_source.map_momentm_status ms
    on ft.SCHEDULE_STATUS = ms.STATUS_CODE
group by all