
  
    

create or replace transient table dw_dev.dev_jkizer.patient_monthly_clinical_values
    copy grants
    
    
    as (with time_period as (
    select
        date_month as period_start_date,
        last_day(date_month) as period_end_date
    from dw_dev.dev_jkizer.dim_date
    where is_bom
      and date_month between dateadd(month, -12, current_date()) and current_date()
),
bp_hr_data as (
    select
        pv.suvida_id,
        tp.period_start_date,
        tp.period_end_date,
        date(pv.document_datetime) as document_datetime,
        pv.min_blood_pressure_systolic,
        pv.min_blood_pressure_diastolic,
        concat(pv.min_blood_pressure_systolic, ' / ', pv.min_blood_pressure_diastolic) as blood_pressure_text,
        not pv.is_lowest_value_controlled_blood_pressure as is_uncontrolled_blood_pressure,
        pv.heart_rate,
        row_number() over (
            partition by pv.suvida_id, tp.period_start_date
            order by
                case when pv.min_blood_pressure_systolic is not null then 0 else 1 end,
                pv.document_datetime desc
        ) as bp_value_index,
        row_number() over (
            partition by pv.suvida_id, tp.period_start_date
            order by
                case when pv.heart_rate is not null then 0 else 1 end,
                pv.document_datetime desc
        ) as hr_value_index
    from dw_dev.dev_jkizer.patient_vital pv
    cross join time_period tp
    where (
        (pv.min_blood_pressure_systolic is not null and pv.min_blood_pressure_diastolic is not null)
        or pv.heart_rate is not null
    )
    and pv.document_datetime <= tp.period_end_date
),

bp_hr_index as (
    select
        period_start_date,
        period_end_date,
        suvida_id,
        -- BP
        max(case when bp_value_index = 1 and min_blood_pressure_systolic is not null then document_datetime end) as most_recent_bp_date,
        max(case when bp_value_index = 1 and min_blood_pressure_systolic is not null then min_blood_pressure_systolic end) as most_recent_bp_systolic,
        max(case when bp_value_index = 1 and min_blood_pressure_systolic is not null then min_blood_pressure_diastolic end) as most_recent_bp_diastolic,
        max(case when bp_value_index = 1 and min_blood_pressure_systolic is not null then blood_pressure_text end) as most_recent_bp,
        max(case when bp_value_index = 2 and min_blood_pressure_systolic is not null then document_datetime end) as second_most_recent_bp_date,
        max(case when bp_value_index = 2 and min_blood_pressure_systolic is not null then min_blood_pressure_systolic end) as second_most_recent_bp_systolic,
        max(case when bp_value_index = 2 and min_blood_pressure_systolic is not null then min_blood_pressure_diastolic end) as second_most_recent_bp_diastolic,
        max(case when bp_value_index = 2 and min_blood_pressure_systolic is not null then blood_pressure_text end) as second_most_recent_bp,
        max(case when bp_value_index = 1 and min_blood_pressure_systolic is not null then is_uncontrolled_blood_pressure end) as is_uncontrolled_bp,
        -- HR
        max(case when hr_value_index = 1 and heart_rate is not null then document_datetime end) as most_recent_hr_date,
        max(case when hr_value_index = 1 and heart_rate is not null then heart_rate end) as most_recent_hr,
        max(case when hr_value_index = 2 and heart_rate is not null then document_datetime end) as second_most_recent_hr_date,
        max(case when hr_value_index = 2 and heart_rate is not null then heart_rate end) as second_most_recent_hr
    from bp_hr_data
    group by period_start_date, period_end_date, suvida_id
),


lab_values_data as (
    select
        flr.suvida_id,
        tp.period_start_date,
        tp.period_end_date,
        date(flr.collected_date) as collected_date,
        -- Handle A1c conversion from text value, otherwise use numeric_test_value
        case
            when lower(flr.test_name) ilike '%a1c%' then try_to_number(replace(flr.test_value, '%', ''), 10, 2)
            else flr.numeric_test_value
        end as lab_value,
        case
            when lower(flr.test_name) ilike '%a1c%' then 'a1c'
            when lower(flr.test_name) ilike '%triglyceride%' then 'triglyceride'
            when lower(flr.test_name) ilike '%ldl%' then 'ldl'
            when lower(flr.test_name) ilike '%hdl%' then 'hdl'
            when lower(flr.test_name) ilike '%cholesterol%' and lower(flr.test_name) ilike '%total%' then 'total_cholesterol'
        end as lab_type,
        -- Add uncontrolled flag for A1c
        case
            when lower(flr.test_name) ilike '%a1c%' and try_to_number(replace(flr.test_value, '%', ''), 10, 2) > 9 then true
            else false
        end as is_uncontrolled_a1c,
        row_number() over (partition by flr.suvida_id, tp.period_start_date,
            case
                when lower(flr.test_name) ilike '%a1c%' then 'a1c'
                when lower(flr.test_name) ilike '%triglyceride%' then 'triglyceride'
                when lower(flr.test_name) ilike '%ldl%' then 'ldl'
                when lower(flr.test_name) ilike '%hdl%' then 'hdl'
                when lower(flr.test_name) ilike '%cholesterol%' and lower(flr.test_name) ilike '%total%' then 'total_cholesterol'
            end
            order by flr.collected_date desc) as value_index
    from dw_dev.dev_jkizer.fct_lab_result flr
    cross join time_period tp
    where (
        lower(flr.test_name) ilike '%a1c%'
        or lower(flr.test_name) ilike '%triglyceride%'
        or lower(flr.test_name) ilike '%ldl%'
        or lower(flr.test_name) ilike '%hdl%'
        or (lower(flr.test_name) ilike '%cholesterol%' and lower(flr.test_name) ilike '%total%')
    )
      and (
        (lower(flr.test_name) ilike '%a1c%' and flr.test_value is not null)
        or (lower(flr.test_name) not ilike '%a1c%' and flr.numeric_test_value is not null)
      )
      and flr.collected_date <= tp.period_end_date
),

lab_values_index as (
    select
        period_start_date,
        period_end_date,
        suvida_id,
        -- A1c
        max(case when lab_type = 'a1c' and value_index = 1 then collected_date end) as most_recent_a1c_date,
        max(case when lab_type = 'a1c' and value_index = 1 then lab_value end) as most_recent_a1c,
        max(case when lab_type = 'a1c' and value_index = 2 then collected_date end) as second_most_recent_a1c_date,
        max(case when lab_type = 'a1c' and value_index = 2 then lab_value end) as second_most_recent_a1c,
        max(case when lab_type = 'a1c' and value_index = 1 then is_uncontrolled_a1c end) as is_uncontrolled_a1c,
        -- Triglycerides
        max(case when lab_type = 'triglyceride' and value_index = 1 then collected_date end) as most_recent_triglyceride_date,
        max(case when lab_type = 'triglyceride' and value_index = 1 then lab_value end) as most_recent_triglyceride,
        max(case when lab_type = 'triglyceride' and value_index = 2 then collected_date end) as second_most_recent_triglyceride_date,
        max(case when lab_type = 'triglyceride' and value_index = 2 then lab_value end) as second_most_recent_triglyceride,
        -- LDL
        max(case when lab_type = 'ldl' and value_index = 1 then collected_date end) as most_recent_ldl_date,
        max(case when lab_type = 'ldl' and value_index = 1 then lab_value end) as most_recent_ldl,
        max(case when lab_type = 'ldl' and value_index = 2 then collected_date end) as second_most_recent_ldl_date,
        max(case when lab_type = 'ldl' and value_index = 2 then lab_value end) as second_most_recent_ldl,
        -- HDL
        max(case when lab_type = 'hdl' and value_index = 1 then collected_date end) as most_recent_hdl_date,
        max(case when lab_type = 'hdl' and value_index = 1 then lab_value end) as most_recent_hdl,
        max(case when lab_type = 'hdl' and value_index = 2 then collected_date end) as second_most_recent_hdl_date,
        max(case when lab_type = 'hdl' and value_index = 2 then lab_value end) as second_most_recent_hdl,
        -- Total Cholesterol
        max(case when lab_type = 'total_cholesterol' and value_index = 1 then collected_date end) as most_recent_total_cholesterol_date,
        max(case when lab_type = 'total_cholesterol' and value_index = 1 then lab_value end) as most_recent_total_cholesterol,
        max(case when lab_type = 'total_cholesterol' and value_index = 2 then collected_date end) as second_most_recent_total_cholesterol_date,
        max(case when lab_type = 'total_cholesterol' and value_index = 2 then lab_value end) as second_most_recent_total_cholesterol
    from lab_values_data
    group by period_start_date, period_end_date, suvida_id
),

combined as (
    select
        coalesce(b.suvida_id, l.suvida_id) as suvida_id,
        coalesce(b.period_start_date, l.period_start_date) as period_start_date,
        coalesce(b.period_end_date, l.period_end_date) as period_end_date,
        iff(coalesce(b.period_start_date, l.period_start_date) = date_trunc(month, current_date()), true, false) as is_current_month,

        -- BP
        b.most_recent_bp_date,
        b.most_recent_bp_systolic,
        b.most_recent_bp_diastolic,
        b.most_recent_bp,
        b.second_most_recent_bp_date,
        b.second_most_recent_bp_systolic,
        b.second_most_recent_bp_diastolic,
        b.second_most_recent_bp,
        b.is_uncontrolled_bp,

        -- HR
        b.most_recent_hr_date,
        b.most_recent_hr,
        b.second_most_recent_hr_date,
        b.second_most_recent_hr,

        -- A1c (now from lab_values_index)
        l.most_recent_a1c_date,
        l.most_recent_a1c,
        l.second_most_recent_a1c_date,
        l.second_most_recent_a1c,
        l.is_uncontrolled_a1c,

        -- Triglycerides
        l.most_recent_triglyceride_date,
        l.most_recent_triglyceride,
        l.second_most_recent_triglyceride_date,
        l.second_most_recent_triglyceride,

        -- LDL
        l.most_recent_ldl_date,
        l.most_recent_ldl,
        l.second_most_recent_ldl_date,
        l.second_most_recent_ldl,

        -- HDL
        l.most_recent_hdl_date,
        l.most_recent_hdl,
        l.second_most_recent_hdl_date,
        l.second_most_recent_hdl,

        -- Total Cholesterol
        l.most_recent_total_cholesterol_date,
        l.most_recent_total_cholesterol,
        l.second_most_recent_total_cholesterol_date,
        l.second_most_recent_total_cholesterol

    from bp_hr_index b
    full join lab_values_index l
      on b.suvida_id = l.suvida_id
      and b.period_start_date = l.period_start_date
)
select
    md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(period_start_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_period_skey,
    *
from combined
    )
;


  