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