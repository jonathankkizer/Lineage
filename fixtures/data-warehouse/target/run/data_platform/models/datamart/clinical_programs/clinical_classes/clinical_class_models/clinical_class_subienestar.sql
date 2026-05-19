
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_class_subienestar
    copy grants
    
    
    as (

  

with base_appointments as (
    select
        suvida_id,
        appointment_provider_category as team,
        case when lower(appointment_type_category) like 'subienestar%' then 'SuBienestar' else null end as program,
        'SuBienestar' as class_name,
        appointment_type_category,
        appointment_date,
        previous_apt_date,
        days_since_last_apt,
        appointment_location_name as location_name,
        appointment_description,
        appointment_status,
        appointment_completed_ind,
        total_apts_attended
    from dw_dev.dev_jkizer.clinical_classes
    where (lower(appointment_type_category) like 'subienestar%')
    and appointment_completed_ind = 1
),

seasons as (
    select
        *,
        case
            when month(appointment_date) between 1 and 4 then 'Spring-' || to_varchar(year(appointment_date))
            when month(appointment_date) between 5 and 8 then 'Summer-' || to_varchar(year(appointment_date))
            when month(appointment_date) between 9 and 12 then 'Fall-' || to_varchar(year(appointment_date))
        end as cohort
    from base_appointments
),

cohorts as (
    select
        *,
        dense_rank() over (
            partition by suvida_id, class_name
            order by
                year(appointment_date),
                case
                    when month(appointment_date) between 1 and 4 then 1  -- Spring (Jan-Apr)
                    when month(appointment_date) between 5 and 8 then 2  -- Summer (May-Aug)
                    when month(appointment_date) between 9 and 12 then 3 -- Fall (Sep-Dec)
                end
        ) as cohort_number
    from seasons
),

final as (
    select
        *,
        row_number() over (partition by suvida_id, class_name, cohort_number 
            order by appointment_date) as apt_number_in_cohort
    from cohorts
),

graduation as (
    select
        suvida_id,
        class_name,
        cohort,
        cohort_number,
        max(apt_number_in_cohort) as apts_attended_in_cohort
    from final
    group by suvida_id, class_name, cohort, cohort_number
)

select
    c.suvida_id,
    c.team,
    c.program,
    c.class_name,
    c.appointment_type_category,
    c.cohort,
    c.cohort_number,
    c.apt_number_in_cohort,
    g.apts_attended_in_cohort,
    c.appointment_date,
    c.previous_apt_date,
    c.days_since_last_apt,
    c.location_name,
    c.appointment_description,
    c.appointment_status,
    c.appointment_completed_ind,
    case when fpt.tag_value = 'Subienestar' then tag_value end as tag_value,
    date(fpt.creation_datetime) as tag_date,
    case
        when appointment_date < '2025-01-01' and fpt.tag_value is not null then 'Graduated'
        when appointment_date >= '2025-01-01'
            and g.apts_attended_in_cohort >= 4
            -- and class_name in ('SuBienestar Class 1', 'SuBienestar Class 2')     -- unreliable until the unique apts are getting labeled correctly, regularly, defaulting to apt count
                then 'Graduated'
                    else 'Not Graduated'
                        end as graduation_status
from final c
join graduation g
    on c.suvida_id = g.suvida_id
    and c.class_name = g.class_name
    and c.cohort = g.cohort
    and c.cohort_number = g.cohort_number
left join dw_dev.dev_jkizer.fct_patient_tag fpt
    on c.suvida_id = fpt.suvida_id
    and lower(fpt.tag_value) = 'subienestar'
    and date_trunc(month, fpt.creation_datetime) = date_trunc(month, c.appointment_date)


  
    )
;


  