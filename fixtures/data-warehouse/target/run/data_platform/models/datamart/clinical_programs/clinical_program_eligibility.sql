
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_program_eligibility
    copy grants
    
    
    as (with  __dbt__cte__rd_subienestar as (
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
      on fa.appointment_type ilike '%subienestar class%'
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
        'subienestar' as program,
        'rd_subienestar' as eligibility_logic
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
),  __dbt__cte__rd_diabetes as (
with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dim_date
    where is_bom = true 
      and date_day between dateadd(month, -18, current_date()) and current_date()
),
a1c_all as (
    select
         tp.date_month_start,
         tp.date_month_end,
         flr.suvida_id,
         flr.numeric_test_value as a1c_value,
         flr.collected_date,
         row_number() over (partition by tp.date_month_start, flr.suvida_id order by flr.collected_date desc) as rn     -- ranking test dates starting with most recent  
    from time_period tp 
    join fct_lab_result flr
      on 1 = 1
      and flr.collected_date between dateadd(month, -6, tp.date_month_start) and tp.date_month_end
    where flr.test_name ilike '%A1c%'
    and numeric_test_value > 9
),
a1c_trigger as (
    select 
        date_month_start,
        date_month_end,
        suvida_id,
        a1c_value,
        collected_date,
        rn
    from a1c_all
)
select
    date_month_start,
    date_month_end,
    suvida_id,
    listagg('A1C: ' || a1c_value || ' | ' || 'Date: '|| to_char(collected_date, 'YYYY-MM-DD'), ' || ')within group (order by rn) as eligibility_evidence,
    'rd' as team,
    'diabetes' as program,
    'rd_diabetes' as eligibility_logic
from a1c_trigger
where rn <= 3           -- only considers 3 most recent tests
group by date_month_start, date_month_end, suvida_id
),  __dbt__cte__rd_hypertension as (
with time_period as (
    select
        date_month           as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -18, current_date()) and current_date()
), 
-- step 1: calculate the daily avg if multiple readings for that day or surface that lone value
daily_bp as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fv.suvida_id,
        date(fv.creation_datetime) as creation_date,
        case 
          when count(*) > 1 then round(avg(fv.blood_pressure_systolic))   -- if more than one reading occurs during the same day, take the avg, else the value
            else max(fv.blood_pressure_systolic)
              end as blood_pressure_systolic,
        case 
          when count(*) > 1 then round(avg(fv.blood_pressure_diastolic))   -- if more than one reading occurs during the same day, take the avg, else the value
          else max(fv.blood_pressure_diastolic)
            end as blood_pressure_diastolic
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_vital fv
      on fv.blood_pressure_text is not null
     and date(fv.creation_datetime) between dateadd('month', -6, tp.date_month_start) and tp.date_month_start
    group by
      tp.date_month_start,
      tp.date_month_end,
      fv.suvida_id,
      date(fv.creation_datetime)
),

-- step 2: select and rank only days with systolic > 140
ranked_bp as (
    select
        dp.date_month_start,
        dp.date_month_end,
        dp.suvida_id,
        dp.creation_date,
        'Systolic BP: ' || dp.blood_pressure_systolic || ' | Date: ' || to_char(dp.creation_date,'YYYY-MM-DD') || ' || ' as eligibility_evidence,
        row_number() over (partition by dp.suvida_id, dp.date_month_start order by dp.creation_date desc) as rn
    from daily_bp dp
    where dp.blood_pressure_systolic > 140
),

-- step 3: keep top 2 days per month and build the evidence string
bp_eligibility as (
    select
        rb.date_month_start,
        rb.date_month_end,
        rb.suvida_id,
        listagg(rb.eligibility_evidence, ' | ')
          within group (order by rb.creation_date desc) as eligibility_evidence,
        'rd' as team,
        'hypertension' as program,
        'rd_hypertension' as eligibility_logic
    from ranked_bp rb
    where rb.rn <= 2
    group by
        rb.suvida_id,
        rb.date_month_start,
        rb.date_month_end
    having count(*) >= 2
),

-- step 4: require at least two PCP visits in the 6 months before each month
pcp_visits as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fe.suvida_id,
        count(distinct fe.encounter_skey) as pcp_visit_count
    from time_period tp
    join dw_dev.dev_jkizer.fct_encounter fe
      on fe.encounter_type  = 'clinical_encounter'
     and fe.visit_note_name = 'Provider Note'
     and fe.encounter_date between dateadd('month', -6, tp.date_month_start) and tp.date_month_end
    group by
      tp.date_month_start,
      tp.date_month_end,
      fe.suvida_id
    having count(distinct fe.encounter_skey) >= 2   -- include only those with 2 or more pcp visits 
)

-- step 5: combine eligibility and visits
    select
        bp.date_month_start,
        bp.date_month_end,
        bp.suvida_id,
        bp.eligibility_evidence,
        bp.team,
        bp.program,
        bp.eligibility_logic
    from bp_eligibility bp
    join pcp_visits pv
      on bp.suvida_id = pv.suvida_id
     and bp.date_month_start  = pv.date_month_start
),  __dbt__cte__rd_malnutrition as (
with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true 
      and date_day >= dateadd(month, -18, current_date())
      and date_day <= current_date()
),
dx_criteria as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fd.suvida_id,
        listagg(distinct fd.icd_10_code || ' | ' || fd.diagnosis_date) as dx_eligibility_evidence,
        'rd' as team,
        'malnutrition' as program,
        'rd_malnutrition' as eligibility_logic
    from time_period tp
    left join fct_diagnosis fd on 1 = 1
    where
        fd.source_type = 'emr'
        and (
            fd.icd_10_code ilike 'E43%' or
            fd.icd_10_code ilike 'E440%' or
            fd.icd_10_code ilike 'R634%'
        )
        and date_trunc(month, fd.diagnosis_date) between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
    group by tp.date_month_start, tp.date_month_end, fd.suvida_id
),
mst_scores as (
    select
        suvida_id,
        completed_at_datetime,
        mst_score,
        'MST Score: ' || mst_score as mst_eligibility_evidence
    from dw_dev.dev_jkizer.patient_mst_screener
    where mst_score >= 2
),
combined_date as (
    select
        dx.date_month_start,
        dx.date_month_end,
        ms.suvida_id,
        ms.completed_at_datetime,
        ms.mst_score,
        dx.dx_eligibility_evidence || ' | ' || ms.mst_eligibility_evidence as eligibility_evidence,
        dx.team,
        dx.program,
        dx.eligibility_logic
    from mst_scores ms
    inner join dx_criteria dx on
        ms.suvida_id = dx.suvida_id
        and ms.completed_at_datetime between dx.date_month_start and dx.date_month_end
)

select
    date_month_start,
    date_month_end,
    suvida_id,
    eligibility_evidence,
    team,
    program,
    eligibility_logic
from combined_date
),  __dbt__cte__rd_hyperlipidemia as (
with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -12, current_date()) and current_date()
),

dx_criteria as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fd.suvida_id,
        listagg(distinct 'Diagnosis Date: ' || fd.diagnosis_date || ' | ', ' ') as dx_eligibility_evidence,
        'rd' as team,
        'hyperlipidemia' as program,
        'rd_hyperlipidemia' as eligibility_logic
    from time_period tp
    join dw_dev.dev_jkizer.fct_diagnosis fd
        on date_trunc(month, fd.diagnosis_date) = tp.date_month_start           -- doing 1 = 1 kept causing a cartesian product and many more dx's than labs
  /*  where
        fd.source_type = 'emr'
       -- and (
            fd.icd_10_code ilike 'e780%' or 
            fd.icd_10_code ilike 'e781%' or
            fd.icd_10_code ilike 'e782%' or
            fd.icd_10_code ilike 'e783%' or
            fd.icd_10_code ilike 'e784%' or
            fd.icd_10_code ilike 'e785%'
        ) */
    group by all
),

lab_criteria as (
    select
        tp.date_month_start,
        tp.date_month_end,
        flr.suvida_id,
        listagg(distinct flr.test_name || ': ' || flr.numeric_test_value, ' | ') as lab_eligibility_evidence,
        'rd' as team,
        'hyperlipidemia' as program,
        'rd_hyperlipidemia' as eligibility_logic
    from time_period tp
    join dw_dev.dev_jkizer.fct_lab_result flr
        on date_trunc(month, flr.collected_date) = tp.date_month_start          -- doing 1 = 1 kept causing a cartesian product and many more dx's than labs
    where
        (
            (flr.test_name = 'Total Cholesterol' and flr.numeric_test_value >= 200)
            or (flr.test_name ilike 'LDL-Cholesterol' and flr.numeric_test_value >= 100)
            or (flr.test_name ilike 'Triglycerides' and flr.numeric_test_value >= 150)
        )
    group by all
)

select
    dx.date_month_start,
    dx.date_month_end,
    dx.suvida_id,
    dx.dx_eligibility_evidence || ' | ' || lab.lab_eligibility_evidence as eligibility_evidence,
    dx.team,
    dx.program,
    dx.eligibility_logic
from dx_criteria dx
join lab_criteria lab
    on dx.suvida_id = lab.suvida_id
    and dx.date_month_start = lab.date_month_start
),  __dbt__cte__rd_food_rx as (
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
),  __dbt__cte__pt_mob as (
with time_period as (
     select
         date_month as date_month_start,
         last_day(date_month) as date_month_end
     from dw_dev.dev_jkizer.dim_date 
     where is_bom = true
       and date_day between dateadd(month, -18, current_date()) and current_date()
),

-- A calendar for all relevant patient-month combinations
calendar as (
    select
        tp.date_month_start,
        tp.date_month_end,
        p.suvida_id
    from time_period tp
    cross join (
        select distinct suvida_id from dw_dev.dev_jkizer.patient_history
        union
        select distinct suvida_id from dw_dev.dev_jkizer.fct_appointment
    ) p
),

-- TUG Pairs for each month within a 6-month window
tug_pairs as (
    select
        cal.date_month_start,
        cal.date_month_end,
        cal.suvida_id,
        listagg(
            'TUG Δ: ' || (coalesce(try_to_decimal(ph.post_tug_value, 10, 2), 0) - coalesce(try_to_decimal(ph.pre_tug_value, 10, 2), 0))::string ||
            ' | Pre: ' || coalesce(try_to_decimal(ph.pre_tug_value, 10, 2), 0)::string || ' (' || to_char(ph.pre_tug_date, 'YYYY-MM-DD') || ')' ||
            ' | Post: ' || coalesce(try_to_decimal(ph.post_tug_value, 10, 2), 0)::string || ' (' || to_char(ph.post_tug_date, 'YYYY-MM-DD') || ')', ' || '
        ) within group (order by ph.pre_tug_date desc) as tug_evidence
    from calendar cal
    inner join dw_dev.dev_jkizer.patient_history ph
        on ph.suvida_id = cal.suvida_id
        and ph.pre_tug_date is not null
        and ph.post_tug_date is not null
        and ph.pre_tug_date between dateadd(month, -6, cal.date_month_start) and cal.date_month_end
    group by cal.date_month_start, cal.date_month_end, cal.suvida_id
),

-- Consolidated MOB visits with a cumulative count for each patient
mob_visits as (
    select
        cal.date_month_start,
        cal.date_month_end,
        cal.suvida_id,
        count(distinct fa.appointment_skey) as monthly_visits,
        max(fa.appointment_date) as most_recent_apt_month,
        sum(monthly_visits)
            over (partition by cal.suvida_id order by cal.date_month_start rows between unbounded preceding and current row) as cumulative_visits,
        max(most_recent_apt_month) 
            over (partition by cal.suvida_id order by cal.date_month_start rows between unbounded preceding and current row) as most_recent_apt_cume
    from calendar cal
    left join dw_dev.dev_jkizer.fct_appointment fa
      on (fa.appointment_type_category = 'Matter of Balance')
     and fa.suvida_id = cal.suvida_id
     and fa.appointment_date between cal.date_month_start and cal.date_month_end
    group by cal.date_month_start, cal.date_month_end, cal.suvida_id
),

-- Final eligibility check using an INNER JOIN to only keep eligible patients
final_eligible as (
    select
        tp.date_month_start,
        tp.date_month_end,
        tp.suvida_id,
        tp.tug_evidence
          || ' | Monthly Visits: ' || coalesce(v.monthly_visits, 0)
          || ' | Cumulative Visits: ' || coalesce(v.cumulative_visits, 0)
          || ' | Most Recent Apt: ' || to_char(coalesce(v.most_recent_apt_cume, '1900-01-01'::date), 'YYYY-MM-DD') as eligibility_evidence,
        'pt' as team,
        'matter_of_balance' as program,
        'pt_matter_of_balance' as eligibility_logic
    from tug_pairs tp
    inner join mob_visits v
      on v.suvida_id = tp.suvida_id
      and v.date_month_start = tp.date_month_start
                                                                -- Graduation criteria: at least 6 out of 9 visits
    where v.cumulative_visits >= 6
)

select 
    date_month_start,
    date_month_end,
    suvida_id,
    eligibility_evidence,
    team,
    program,
    eligibility_logic
from final_eligible
),  __dbt__cte__pt_post_stroke as (
with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true 
      and date_day >= dateadd(month, -12, current_date()) 
      and date_day <= current_date()
),
dx_criteria as (
    select 
        tp.date_month_start,
        tp.date_month_end,
        fd.suvida_id,
        listagg(
            distinct 'Stroke Diagnosis Date: ' || fd.diagnosis_date || ' | ' || fd.icd_10_code || ' | ' || fd.icd_10_code_description || ' || '
        ) as eligibility_evidence,
        'pt' as team,
        'post_stroke' as program,
        'pt_post_stroke' as eligibility_logic
    from time_period tp
    left join dw_dev.dev_jkizer.fct_diagnosis fd
        on 1 = 1
    where
        fd.diagnosis_date between dateadd(month, -12, tp.date_month_start) and tp.date_month_end
        and source_type ilike 'emr'
        and (
            fd.icd_10_code ilike 'I60%' or
            fd.icd_10_code ilike 'I61%' or
            fd.icd_10_code ilike 'I62%' or
            fd.icd_10_code ilike 'I63%' or 
            fd.icd_10_code ilike 'I64%' or
            fd.icd_10_code ilike 'G45%' or
            fd.icd_10_code ilike 'G81%'
        )
    group by all
)
select
    date_month_start,
    date_month_end,
    suvida_id,
    eligibility_evidence,
    team,
    program,
    eligibility_logic
from dx_criteria
),  __dbt__cte__pharmd_polypharm as (
with time_period as (
    
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -18, current_date()) and current_date()

),

polypharm_eligibility as (

    select 
        tp.date_month_start,
        tp.date_month_end,
        fqm.suvida_id,
        
        listagg(distinct fqm.measure_source || ' | ' || cast(fqm.report_date as string) || ' || ') as eligibility_evidence,
        
        'pharmd' as team,
        'polypharm' as program,
        'pharmd_polypharm' as eligibility_logic

    from time_period tp

    left join dw_dev.dev_jkizer.fct_quality_measure fqm 
        on date_trunc(month, fqm.report_date) between dateadd(month, -1, tp.date_month_start) and tp.date_month_start

    where fqm.quality_measure ilike 'Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults'
      and fqm.quality_report_in_month_rank = 1
      and fqm.measure_denominator = 1
      and fqm.measure_numerator = 0

    group by
        tp.date_month_start,
        tp.date_month_end,
        fqm.suvida_id

)

select
    date_month_start,
    date_month_end,
    suvida_id,
    eligibility_evidence,
    team,
    program,
    eligibility_logic

from polypharm_eligibility
order by date_month_start, suvida_id
),  __dbt__cte__pharmd_hypertension as (
with time_period as (
    select
        date_month           as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true
      and date_day between dateadd(month, -18, current_date()) and current_date()
), 
-- step 1: calculate the daily avg if multiple readings for that day or surface that lone value
daily_bp as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fv.suvida_id,
        date(fv.creation_datetime) as creation_date,
        case 
          when count(*) > 1 then round(avg(fv.blood_pressure_systolic))   -- if more than one reading occurs during the same day, take the avg, else the value
            else max(fv.blood_pressure_systolic)
              end as blood_pressure_systolic,
        case 
          when count(*) > 1 then round(avg(fv.blood_pressure_diastolic))   -- if more than one reading occurs during the same day, take the avg, else the value
          else max(fv.blood_pressure_diastolic)
            end as blood_pressure_diastolic
    from time_period tp
    inner join dw_dev.dev_jkizer.fct_vital fv
      on fv.blood_pressure_text is not null
     and date(fv.creation_datetime) between dateadd('month', -6, tp.date_month_start) and tp.date_month_start
    group by
      tp.date_month_start,
      tp.date_month_end,
      fv.suvida_id,
      date(fv.creation_datetime)
),

-- step 2: select and rank only days with systolic > 140
ranked_bp as (
    select
        dp.date_month_start,
        dp.date_month_end,
        dp.suvida_id,
        dp.creation_date,
        'Systolic BP: ' || dp.blood_pressure_systolic || ' | ' || 'Date: ' || to_char(dp.creation_date,'YYYY-MM-DD') as eligibility_evidence,
        row_number() over (partition by dp.suvida_id, dp.date_month_start order by dp.creation_date desc) as rn
    from daily_bp dp
    where dp.blood_pressure_systolic > 140
),

-- step 3: keep top 2 days per month and build the evidence string
bp_eligibility as (
    select
        rb.date_month_start,
        rb.date_month_end,
        rb.suvida_id,
        listagg(rb.eligibility_evidence, ' | ')
          within group (order by rb.creation_date desc) as eligibility_evidence,
        'pharmd' as team,
        'hypertension' as program,
        'pharmd_hypertension' as eligibility_logic
    from ranked_bp rb
    where rb.rn <= 2
    group by
        rb.suvida_id,
        rb.date_month_start,
        rb.date_month_end
    having count(*) >= 2
),

-- step 4: require at least two PCP visits in the 6 months before each month
pcp_visits as (
    select
        tp.date_month_start,
        tp.date_month_end,
        fe.suvida_id,
        count(distinct fe.encounter_skey) as pcp_visit_count
    from time_period tp
    join dw_dev.dev_jkizer.fct_encounter fe
      on fe.encounter_type  = 'clinical_encounter'
     and fe.visit_note_name = 'Provider Note'
     and fe.encounter_date between dateadd('month', -6, tp.date_month_start) and tp.date_month_end
    group by
      tp.date_month_start,
      tp.date_month_end,
      fe.suvida_id
    having count(distinct fe.encounter_skey) >= 2   -- include only those with 2 or more pcp visits 
)

-- step 5: combine eligibility and visits
    select
        bp.date_month_start,
        bp.date_month_end,
        bp.suvida_id,
        bp.eligibility_evidence,
        bp.team,
        bp.program,
        bp.eligibility_logic
    from bp_eligibility bp
    join pcp_visits pv
      on bp.suvida_id = pv.suvida_id
     and bp.date_month_start  = pv.date_month_start
),  __dbt__cte__pharmd_supd as (
with time_period as (
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end,
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
)
select
	tp.date_month_start,
	tp.date_month_end,
	fqm.suvida_id,
	listagg(distinct fqm.measure_source || ' | ' || cast(fqm.report_date as string), ' || ') as eligibility_evidence,
	'pharmd' as team,
	'supd' as program,
	'pharmd_supd' as eligibility_logic
from time_period tp
inner join dw_dev.dev_jkizer.fct_quality_measure fqm
	on 1=1
where fqm.quality_measure = 'Statin Use in Persons with Diabetes'
and year(date_month_start) = year(fqm.measure_year)
and fqm.quality_report_in_month_rank = 1
and fqm.measure_numerator = 0
and date_trunc(month, fqm.report_date) = date_month_start
group by tp.date_month_start, tp.date_month_end, fqm.suvida_id
),  __dbt__cte__pharmd_statin as (
with time_period as 
(
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true 
      and date_day between dateadd(month, -18, current_date()) and current_date()
),
lab_criteria as
(
    select
        tp.date_month_start,
        tp.date_month_end,
        fqm.suvida_id,
        listagg(distinct 'Statin use with CVD: ' || coalesce(fqm.quality_measure, '') || ' | ')
            as eligibility_evidence,
        'pharmd' as team,
        'statin_cvd' as program,
        'pharmd_statin_cvd' as eligibility_logic
    from time_period tp 
    left join dw_dev.dev_jkizer.fct_quality_measure fqm
        on 1 = 1
    where
           fqm.quality_measure ilike '%Statin Therapy for Cardiovascular Disease%'
           and year(date_month_start) = year(fqm.measure_year)
           and fqm.quality_report_in_month_rank = 1
           and fqm.measure_numerator = 0
           and date_trunc(month, fqm.report_date) = date_month_start
    group by all
)   
select
    date_month_start,
    date_month_end,
    suvida_id,
    eligibility_evidence,
    team,
    program,
    eligibility_logic
from lab_criteria
),  __dbt__cte__pharmd_diabetes as (
with time_period as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end
    from dw_dev.dev_jkizer.dim_date
    where is_bom = true 
      and date_day between dateadd(month, -18, current_date()) and current_date()
),
a1c_all as (
    select
         tp.date_month_start,
         tp.date_month_end,
         flr.suvida_id,
         flr.numeric_test_value as a1c_value,
         flr.collected_date,
         row_number() over (partition by tp.date_month_start, flr.suvida_id order by flr.collected_date desc) as rn     -- ranking test dates starting with most recent  
    from time_period tp 
    join dw_dev.dev_jkizer.fct_lab_result flr
      on 1 = 1
      and flr.collected_date between dateadd(month, -6, tp.date_month_start) and tp.date_month_end
    where flr.test_name ilike '%A1c%'
    and numeric_test_value > 9
),
a1c_trigger as (
    select 
        date_month_start,
        date_month_end,
        suvida_id,
        a1c_value,
        collected_date,
        rn
    from a1c_all
)
select
    date_month_start,
    date_month_end,
    suvida_id,
    listagg('A1C: ' || a1c_value || ' | ' || 'Date: ' ||  to_char(collected_date, 'YYYY-MM-DD'), ' || ')within group (order by collected_date, rn) as eligibility_evidence,
    'pharmd' as team,
    'diabetes' as program,
    'pharmd_diabetes' as eligibility_logic
from a1c_trigger
where rn <= 3           -- only considers 3 most recent tests
group by date_month_start, date_month_end, suvida_id
),  __dbt__cte__pharmd_chf as (
with time_period as (
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end,
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
), chf_stage_c_d as (
	select
		siw.suvida_id,
		im.imo_description,
		min(pp.start_date) as start_date,
		greatest_ignore_nulls(max(pp.resolved_date), max(pp.deletion_datetime), '2099-12-31') as end_date,
	from dw_dev.dev_jkizer_staging.stg_elation_patient_problem pp
	inner join dw_dev.dev_jkizer_staging.stg_elation_patient_problem_code ppc
		on pp.patient_problem_id = ppc.patient_problem_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_imo im
		on ppc.imo_code = im.imo_code
	inner join dw_dev.dev_jkizer_staging.stg_elation_icd10 ic
		on ppc.icd10 = ic.icd10_id
		and im.uq_id = ic.imo_id
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on pp.patient_id = siw.member_id
		and siw.source = 'Elation'
	where im.imo_description ilike '%chf%' and (im.imo_description ilike '%stage c%' or im.imo_description ilike '%stage d%')
	group by all
)
select
	tp.date_month_start,
	tp.date_month_end,
	c.suvida_id,
	c.imo_description as eligibility_evidence,
	'pharmd' as team,
	'chf' as program,
	'pharmd_chf' as eligibility_logic,
from time_period tp
inner join chf_stage_c_d c 
	on 1=1
where tp.date_month_start >= c.start_date and tp.date_month_start <= end_date
),  __dbt__cte__mh_psychiatry as (
with time_period as ( -- create date spine so we can create rolling periods of time
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
), mh_p_dx as ( -- grab patients with specific diagnoses within specified rolling time period
	select
		tp.date_month_start,
		tp.date_month_end,
		fd.suvida_id,
		max(fd.diagnosis_date) || ' - ' || listagg(distinct fd.icd_10_code, ' | ') as eligibility_evidence
	from time_period tp 
	inner join dw_dev.dev_jkizer.fct_diagnosis fd
		on 1=1
	where diagnosis_date >= dateadd(month, -12, tp.date_month_start)
	and diagnosis_date <= tp.date_month_start
	and source_type = 'emr'
	and (icd_10_code ilike 'F42%' 
		or icd_10_code ilike 'F20%' 
		or icd_10_code ilike 'F25%' 
		or icd_10_code ilike 'F31%' 
		or icd_10_code ilike 'F33%')
	and suvida_id is not null
	group by all
), mh_p_screener as ( -- grab patients with screener results above specified value
	select
		tp.date_month_start,
		tp.date_month_end,
		ph.suvida_id,
		history_type || ' - ' || history_value_numeric || ' - ' || date(ph.creation_datetime) as eligibility_evidence
	from time_period tp
	inner join dw_dev.dev_jkizer.fct_patient_history ph
		on 1=1
	where creation_datetime >= dateadd(month, -12, tp.date_month_start)
	and creation_datetime <= tp.date_month_start
	and history_type in ('GAD-7', 'PHQ-9')
	and history_value_numeric >= 15
	and suvida_id is not null
	qualify row_number() over (partition by suvida_id, date_month_start order by creation_datetime desc, history_value_numeric desc) = 1
)
select
	date_month_start,
	date_month_end,
	suvida_id,
	array_to_string(array_construct_compact(s.eligibility_evidence, d.eligibility_evidence), ' | ') as eligibility_evidence,
	'mh' as team,
	'mh_p' as program,
	'mh_psychiatry' as eligibility_logic
from mh_p_dx d  
inner join mh_p_screener s 
	using (date_month_start, date_month_end, suvida_id)
),  __dbt__cte__mh_therapy_individual as (
with time_period as ( -- create date spine so we can create rolling periods of time
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
), mh_p_dx as ( -- grab patients with specific diagnoses within specified rolling time period
	select
		tp.date_month_start,
		tp.date_month_end,
		fd.suvida_id,
		max(fd.diagnosis_date) || ' - ' || listagg(distinct fd.icd_10_code, ' | ') as eligibility_evidence
	from time_period tp 
	inner join dw_dev.dev_jkizer.fct_diagnosis fd
		on 1=1
	where diagnosis_date >= dateadd(month, -12, tp.date_month_start)
	and diagnosis_date <= tp.date_month_start
	and source_type = 'emr'
	and (icd_10_code ilike 'F32%' 
		or icd_10_code ilike 'F33%' 
		or icd_10_code ilike 'F411%' 
		or icd_10_code ilike 'F410%' 
		or icd_10_code ilike 'F4310%'	--added PTSD
	)
	and suvida_id is not null
	group by all
), mh_p_screener as ( -- grab patients with screener results above specified value
	select
		tp.date_month_start,
		tp.date_month_end,
		ph.suvida_id,
		history_type || ' - ' || history_value_numeric || ' - ' || date(ph.creation_datetime) as eligibility_evidence
	from time_period tp
	inner join dw_dev.dev_jkizer.fct_patient_history ph
		on 1=1
	where creation_datetime >= dateadd(month, -12, tp.date_month_start)
	and creation_datetime <= tp.date_month_start
	and history_type in ('GAD-7', 'PHQ-9')		-- allow any value
	and suvida_id is not null
	qualify row_number() over (partition by suvida_id, date_month_start order by creation_datetime desc, history_value_numeric desc) = 1
)
select
	date_month_start,
	date_month_end,
	suvida_id,
	array_to_string(array_construct_compact(s.eligibility_evidence, d.eligibility_evidence), ' | ') as eligibility_evidence,
	'mh' as team,
	'mh_t_individual' as program,
	'mh_therapy_individual' as eligibility_logic
from mh_p_dx d 
inner join mh_p_screener s 
	using (date_month_start, date_month_end, suvida_id)
),  __dbt__cte__mh_therapy_group as (
with time_period as ( -- create date spine so we can create rolling periods of time
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
), mh_p_dx as ( -- grab patients with specific diagnoses within specified rolling time period
	select
		tp.date_month_start,
		tp.date_month_end,
		fd.suvida_id,
		max(fd.diagnosis_date) || ' - ' || listagg(distinct fd.icd_10_code, ' | ') as eligibility_evidence
	from time_period tp 
	inner join dw_dev.dev_jkizer.fct_diagnosis fd
		on 1=1
	where diagnosis_date >= dateadd(month, -12, tp.date_month_start)
	and diagnosis_date <= tp.date_month_start
	and source_type = 'emr'
	and icd_10_code = 'F4321'
	and suvida_id is not null
	group by all
), mh_p_screener as ( -- grab patients with screener results above specified value
	select
		tp.date_month_start,
		tp.date_month_end,
		ph.suvida_id,
		history_type || ' - ' || history_value_numeric || ' - ' || date(ph.creation_datetime) as eligibility_evidence
	from time_period tp
	inner join dw_dev.dev_jkizer.fct_patient_history ph
		on 1=1
	where creation_datetime >= dateadd(month, -12, tp.date_month_start)
	and creation_datetime <= tp.date_month_start
	and history_type in ('GAD-7', 'PHQ-9')
	and history_value_numeric is not null		-- allow any value if present
	and suvida_id is not null
	qualify row_number() over (partition by suvida_id, date_month_start order by creation_datetime desc, history_value_numeric desc) = 1
)
select
	d.date_month_start,
	d.date_month_end,
	d.suvida_id,
	array_to_string(array_construct_compact(s.eligibility_evidence, d.eligibility_evidence), ' | ') as eligibility_evidence,
	'mh' as team,
	'mh_t_group' as program,
	'mh_therapy_group' as eligibility_logic
from mh_p_dx d 
inner join mh_p_screener s 
	on d.date_month_start = s.date_month_start
    and d.date_month_end = s.date_month_end
    and d.suvida_id = s.suvida_id
), rollup_candidates as (
	select *
	from __dbt__cte__rd_subienestar
	
	union all
	
	select *
	from __dbt__cte__rd_diabetes
	
	union all
	
	select *
	from __dbt__cte__rd_hypertension
	
	union all
	
	select *
	from __dbt__cte__rd_malnutrition
	
	union all
	
	select *
	from __dbt__cte__rd_hyperlipidemia
	
	union all
	
	select * 
	from __dbt__cte__rd_food_rx
	
	union all
	
	select *
	from __dbt__cte__pt_mob
	
	union all
	
	select *
	from __dbt__cte__pt_post_stroke
	
), rd_rollup as (
	select
		date_month_start,
		date_month_end,
		suvida_id,
		team,
		program,
		listagg(eligibility_evidence) as eligibility_evidence,
		listagg(eligibility_logic , ' || ') as eligibility_logic
	from rollup_candidates
	group by all

), program_eligibility as (
	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__pharmd_polypharm

	union all

	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__pharmd_hypertension
	
	union all

	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__pharmd_supd

	union all

	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__pharmd_statin
	
	union all

	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__pharmd_diabetes
	
	union all
	
	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__pharmd_chf
	
	union all
	
	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__mh_psychiatry
	
	union all
	
	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__mh_therapy_individual
	
	union all
	
	select
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from __dbt__cte__mh_therapy_group
	
	union all
	
	select 
		date_month_start,
		date_month_end,
		suvida_id,
		eligibility_evidence,
		team,
		program,
		eligibility_logic
	from rd_rollup
)
select
	md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(date_month_start as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(date_month_end as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(team as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(program as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as clinical_program_eligibility_skey,
	pe.*,
	iff(lag(suvida_id) over (partition by team, program, suvida_id order by date_month_start asc) is null, true, false) as is_newly_eligible
from program_eligibility pe
    )
;


  