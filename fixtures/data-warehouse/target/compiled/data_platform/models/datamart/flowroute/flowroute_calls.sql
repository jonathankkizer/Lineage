-- if outbound, means Suvida is calling a patient with destination = their phone number and number_alias = their name (?) and callerid = our phone number
-- if inbound, means someone is calling Suvida with destination = our office phone number and number_alias = our staff name and callerid = their phone number 


with base_calls as (
    -- Filter and prepare base call data
    select 
        *,
        cdr_id as unique_call_id
    from dw_dev.dev_jkizer_staging.stg_flowroute_cdr_exports
    where start_time >= to_timestamp(dateadd(month, -24, current_date()))
    
        and start_time > (select coalesce(max(start_time), to_timestamp('1900-01-01')) from dw_dev.dev_jkizer.flowroute_calls )
    
    
    -- incremental; only add rows that are greater than the most recent start_time
),

normalized_patients as (
    -- Pre-calculate phone number formats to avoid runtime concatenation
    select 
        *,
        concat('1', phone) as phone_with_1,
        concat('+1', phone) as phone_with_plus1
    from dw_dev.dev_jkizer.dim_patient
    where phone is not null
),

normalized_mapping as (
    -- Pre-calculate phone number formats for mapping
    select 
        *,
        concat('+', value) as value_with_plus
    from dw_dev.dev_jkizer_source.map_flowroute_alias
    where market is not null
),

-- Split patient calls by direction for optimal joins
outbound_patient_calls as (
    -- Suvida calling patients (destination = patient phone)
    select 
        bc.unique_call_id,
        np.location_name as patient_location,
        np.market_name as patient_market,
        np.suvida_id
    from base_calls bc
    inner join normalized_patients np 
        on np.phone_with_1 = bc.destination
    where bc.direction = 'outbound'
),

inbound_patient_calls as (
    -- Patients calling Suvida (callerid = patient phone)
    select 
        bc.unique_call_id,
        np.location_name as patient_location,
        np.market_name as patient_market,
        np.suvida_id
    from base_calls bc
    inner join normalized_patients np 
        on np.phone_with_plus1 = bc.callerid
    where bc.direction = 'inbound'
),

all_patient_calls as (
    -- Combine all patient-related calls
    select * from outbound_patient_calls
    union all
    select * from inbound_patient_calls
),

-- Split center mapping by direction for optimal joins
outbound_center_calls as (
    -- Calls FROM Suvida centers (callerid = center phone)
    select 
        bc.unique_call_id,
        nm.clinic as center_clinic,
        nm.market as center_market
    from base_calls bc
    inner join normalized_mapping nm 
        on nm.value_with_plus = bc.callerid
    where bc.direction = 'outbound'
),

inbound_center_calls as (
    -- Calls TO Suvida centers (destination = center phone)
    select 
        bc.unique_call_id,
        nm.clinic as center_clinic,
        nm.market as center_market
    from base_calls bc
    inner join normalized_mapping nm 
        on nm.value = bc.destination
    where bc.direction = 'inbound'
),

all_center_calls as (
    -- Combine all center-related calls
    select * from outbound_center_calls
    union all
    select * from inbound_center_calls
)

-- Final output with optimized joins
select 
    md5(cast(coalesce(cast(bc.direction as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bc.start_time as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bc.destination as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bc.total_cost as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bc.callerid as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(bc.result as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as flowroute_skey,
    bc.direction, 
    bc.start_time,
    bc.end_time, 
    (bc.duration/60.0) as duration_in_minutes, 
    bc.destination as destination_phone_number, 
    bc.number_alias as destination_contact_name,
    bc.callerid as callerid_phone_number,
    coalesce(acc.center_clinic, apc.patient_location) as clinic,
    coalesce(acc.center_market, apc.patient_market) as market_name,
    bc.total_cost, 
    bc.result as call_result, 
    bc.call_fail_reason,
    apc.suvida_id
from base_calls bc
left join all_center_calls acc 
    on bc.unique_call_id = acc.unique_call_id
left join all_patient_calls apc 
    on bc.unique_call_id = apc.unique_call_id
group by all