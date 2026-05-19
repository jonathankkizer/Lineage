with addresses as (
    select
        pt.suvida_id,
        pt.elation_id,
        pa.address_id,
        case
            when pa.suvida_id is not null and pa.street_1 is not null then pa.street_1
            else pt.address_line_1
        end as street_1,
        case
            when pa.suvida_id is not null then pa.street_number
            else null
        end as street_number,
        case
            when pa.suvida_id is not null then pa.street_name
            else null
        end as street_name,
        pt.address_line_2 as unit,
        case
            when pa.suvida_id is not null then pa.city
            when cities.city_name is not null then cities.city_name
            else pt.city
        end as city,
        case
            when pa.suvida_id is not null then pa.state
            else pt.state
        end as state,
        case
            when pa.suvida_id is not null then pa.zip
            else pt.zip
        end as zip,
        pa.longitude,
        pa.latitude
    from dw_dev.dev_jkizer.dim_patient pt
    left join dw_dev.dev_jkizer.patient_summary ps
        on pt.suvida_id = ps.suvida_id
    left join source_prod.misc.src_misc_cities cities 
        on trim(pt.city) = lower(cities.city_name)
    left join dw_dev.dev_jkizer_staging.patient_addresses pa
        on ps.suvida_id = pa.suvida_id and
           lower(coalesce(ps.address_line_1, '')) = lower(pa.address_line_1_key) and
           lower(coalesce(ps.address_line_2, '')) = lower(pa.address_line_2_key) and
           lower(coalesce(ps.city, '')) = lower(pa.city_key) and
           lower(coalesce(ps.state, '')) = lower(pa.state_key) and
           lower(coalesce(ps.zip, '')) = lower(pa.zip_key) and
           pa.source = 'Google'
    where        
        pt.elation_id is not null and
        (pt.is_active_enrollment = 1 or ps.next_careteam_appt_date is not null) and
        pt.elation_status <> 'deceased'
),

geocoded_addresses as (
    select *
    from addresses
    where 
        address_id is not null
),

ungeocoded_addresses as (
    select
        suvida_id,
        adpts.value as street_number,
        trim(replace(addr.street_1, adpts.value, '')) as street_name,
        addr.unit,
        addr.city,
        addr.state,
        addr.zip
    from addresses addr
    cross join lateral split_to_table(addr.street_1, ' ') as adpts
    where
        address_id is null and 
        adpts.index = 1
),

all_zentake_hra_submissions_wheelchair as (
    select distinct
        customer_elation_id
    from dw_dev.dev_jkizer_staging.stg_zentake_form stgzf
    inner join addresses addr
        on stgzf.customer_elation_id = addr.elation_id
    where
        form_id in ('268410a4-85bc-4349-9c52-cdde82d31f6e', 'c6731d44-4148-4cce-80db-26c4b622fae2') and
        stand_question = 'Which of these assistive devices do you use?' and
        question_answer = 'Wheelchair'
),

all_zentake_hra_submissions as (
    select distinct
        stgzf.customer_elation_id,
        form_id,
        stand_question,
        question_answer,
        completed_at_datetime
    from dw_dev.dev_jkizer_staging.stg_zentake_form stgzf
    inner join all_zentake_hra_submissions_wheelchair azhsw
        on stgzf.customer_elation_id = azhsw.customer_elation_id
    where
        form_id in ('268410a4-85bc-4349-9c52-cdde82d31f6e', 'c6731d44-4148-4cce-80db-26c4b622fae2') and
        stand_question = 'Which of these assistive devices do you use?' and
        question_answer in ('Wheelchair', 'None')
),

ordered_zentake_hra_submissions_wheelchair as (
    select
        *,
        row_number() over(
            partition by customer_elation_id, form_id
            order by completed_at_datetime desc
        ) submission
    from all_zentake_hra_submissions
),

wheelchair_patients as (
    select
        patient_id as customer_elation_id
    from dw_dev.dev_jkizer_staging.stg_elation_patient_tag
    where
        tag_value = 'Wheelchair' and
        deletion_datetime is null

    union all

    select
        customer_elation_id
    from ordered_zentake_hra_submissions_wheelchair
    where
        submission = 1 and
        question_answer = 'Wheelchair'
),

distinct_wheelchair_patients as (
    select distinct
        customer_elation_id
    from wheelchair_patients
)

select
	initcap(pt.first_name) as first_name,
    initcap(pt.last_name) as last_name,
    case
        when pt.middle_name is not null then initcap(pt.middle_name)
        when pt.middle_initial is not null then initcap(pt.middle_initial)
        else null
    end as middle_name,
    case
        when lower(pt.gender) = 'female' then 'F'
        when lower(pt.gender) = 'f' then 'F'
        when lower(pt.gender) = 'male' then 'M'
        when lower(pt.gender) = 'm' then 'M'
        else null
    end as gender,
    pt.elation_id,
    pt.birth_date,
    null as comments,
    null as client_code,
    ps.transportation_disability_desc as disability,
    null as mobility_aids,
    case 
        when dwp.customer_elation_id is not null then 'WC'
        else 'AM'
    end as default_space_type,
    case
        when pt.elation_status = 'active' then 'PATIENT'
        when pt.elation_status = 'prospect' then 'PRSPCTS'
        else null
    end as default_passenger_type,
    null as from_date,
    null as "to_date",
    null as client_status,
    ageo.street_number,
    ageo.street_name,
    ageo.unit,
    ageo.city,
    ageo.state,
    ageo.zip,
    iff(ageo.street_1 is null or ageo.street_1 = '', null, ageo.longitude) as longitude,
    iff(ageo.street_1 is null or ageo.street_1 = '', null, ageo.latitude) as latitude,
    case
        when ageo.address_id is not null and ageo.street_1 is not null and ageo.street_1 <> '' then 'yes'
        else 'no'
    end as is_geocoded,
    pt.phone,
    --coalesce(ml.momentm_location_name, pt.location_name) as location_name,
    pt.location_name,
    ps.transportation_flag
from geocoded_addresses ageo
left join dw_dev.dev_jkizer.dim_patient pt
    on ageo.suvida_id = pt.suvida_id
left join dw_dev.dev_jkizer.patient_summary ps
    on pt.suvida_id = ps.suvida_id
/*left join dw_dev.dev_jkizer_source.map_momentm_location ml
    on trim(lower(pt.location_name)) = trim(lower(ml.location_name))
*/
left join distinct_wheelchair_patients dwp
    on pt.elation_id = dwp.customer_elation_id

union all

select
	initcap(pt.first_name) as first_name,
    initcap(pt.last_name) as last_name,
    case
        when pt.middle_name is not null then initcap(pt.middle_name)
        when pt.middle_initial is not null then initcap(pt.middle_initial)
        else null
    end as middle_name,
    case
        when lower(pt.gender) = 'female' then 'F'
        when lower(pt.gender) = 'f' then 'F'
        when lower(pt.gender) = 'male' then 'M'
        when lower(pt.gender) = 'm' then 'M'
        else null
    end as gender,
    pt.elation_id,
    pt.birth_date,
    null as comments,
    null as client_code,
    ps.transportation_disability_desc as disability,
    null as mobility_aids,
    case 
        when dwp.customer_elation_id is not null then 'WC'
        else 'AM'
    end as default_space_type,
    case
        when pt.elation_status = 'active' then 'PATIENT'
        when pt.elation_status = 'prospect' then 'PRSPCTS'
        else null
    end as default_passenger_type,
    null as from_date,
    null as "to_date",
    null as client_status,
    ungeo.street_number,
    ungeo.street_name,
    ungeo.unit,
    ungeo.city,
    ungeo.state,
    ungeo.zip,
    null as longitude,
    null as latitude,
    'no' as is_geocoded,
    pt.phone,
    --coalesce(ml.momentm_location_name, pt.location_name) as location_name,
    pt.location_name,
    ps.transportation_flag    
from ungeocoded_addresses ungeo
left join dw_dev.dev_jkizer.dim_patient pt
    on ungeo.suvida_id = pt.suvida_id
left join dw_dev.dev_jkizer.patient_summary ps
    on pt.suvida_id = ps.suvida_id
/*
left join dw_dev.dev_jkizer_source.map_momentm_location ml
    on trim(lower(pt.location_name)) = trim(lower(ml.location_name))
*/
left join distinct_wheelchair_patients dwp
    on pt.elation_id = dwp.customer_elation_id