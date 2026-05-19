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