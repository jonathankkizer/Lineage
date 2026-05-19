-- models/eligibility/food_rx_eligibility.sql

with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -18, current_date()) and current_date()
),

a1c_keep as (
    select
        tp.date_month_start,
        tp.date_month_end,
        flr.suvida_id,
        'A1c: ' || flr.numeric_test_value || ' | ' || to_char(flr.collected_date, 'YYYY-MM-DD') as a1c_evidence
    from time_period tp
    join dw_dev.dev_jkizer.fct_lab_result flr
      on flr.collected_date between dateadd(month, -6, tp.date_month_start) and tp.date_month_end
    where flr.test_name ilike '%a1c%'
      and flr.numeric_test_value > 9
    qualify row_number() over (partition by flr.suvida_id, tp.date_month_start order by flr.collected_date desc) = 1
),

daily_bp as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fv.suvida_id,
        date(fv.creation_datetime) as creation_date,
        case when count(*) > 1 then round(avg(fv.blood_pressure_systolic))
             else max(fv.blood_pressure_systolic) end as blood_pressure_systolic,
        case when count(*) > 1 then round(avg(fv.blood_pressure_diastolic))
             else max(fv.blood_pressure_diastolic) end as blood_pressure_diastolic
    from time_period tp
    join dw_dev.dev_jkizer.fct_vital fv
      on date(fv.creation_datetime) between dateadd(month, -6, tp.date_month_start) and tp.date_month_end
     and fv.blood_pressure_text is not null
    group by tp.date_month_start, tp.date_month_end, fv.suvida_id, date(fv.creation_datetime)
),

ranked_bp as (
    select
        dp.date_month_start,
        dp.date_month_end,
        dp.suvida_id,
        dp.creation_date,
        'BP: ' || dp.blood_pressure_systolic || '/' || dp.blood_pressure_diastolic ||
        ' | Date: ' || to_char(dp.creation_date, 'YYYY-MM-DD') as bp_evidence,
        row_number() over (partition by dp.suvida_id, dp.date_month_start order by dp.creation_date desc) as rn
    from daily_bp dp
    where dp.blood_pressure_systolic > 140
),

bp_eligibility as (
    select
        rb.date_month_start,
        rb.date_month_end,
        rb.suvida_id,
        listagg(rb.bp_evidence, ' | ') within group (order by rb.creation_date desc) as bp_evidence
    from ranked_bp rb
    where rb.rn <= 2
    group by rb.suvida_id, rb.date_month_start, rb.date_month_end
    having count(*) >= 2
),

foodrx_visits as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fa.suvida_id,
        count(distinct fa.appointment_skey) as visits_this_month,
        max(fa.appointment_date) as most_recent_apt_month,
        sum(count(distinct fa.appointment_skey)) over (partition by fa.suvida_id order by tp.date_month_start) as visits_cume,
        max(max(fa.appointment_date)) over (partition by fa.suvida_id order by tp.date_month_start) as most_recent_apt_cume,
        12 as expected_sessions_cume
    from time_period tp
    join dw_dev.dev_jkizer.fct_appointment fa
      on fa.appointment_type ilike '%food rx%'
     and fa.appointment_date between tp.date_month_start and tp.date_month_end
    group by tp.date_month_start, tp.date_month_end, fa.suvida_id
),

combined as (
    select
        a.suvida_id,
        a.date_month_start,
        a.date_month_end,
        a.a1c_evidence || ' | ' || b.bp_evidence ||
        ' | Monthly visits: ' || coalesce(v.visits_this_month, 0) ||
        ' | Most Recent: ' || to_char(coalesce(v.most_recent_apt_month, '1900-01-01'::date), 'YYYY-MM-DD') ||
        ' | Cumulative visits: ' || coalesce(v.visits_cume, 0) || ' / ' || coalesce(v.expected_sessions_cume, 12)
        as eligibility_evidence,
        'rd' as team,
        'food_rx' as program,
        'rd_food_rx' as eligibility_logic
    from a1c_keep a
    join bp_eligibility b
      on a.suvida_id = b.suvida_id
     and a.date_month_start = b.date_month_start
     and a.date_month_end = b.date_month_end
    left join foodrx_visits v
      on a.suvida_id = v.suvida_id
     and a.date_month_start = v.date_month_start
     and a.date_month_end = v.date_month_end
)

select
    date_month_start,
    date_month_end,
    suvida_id,
    eligibility_evidence,
    team,
    program,
    eligibility_logic
from combined