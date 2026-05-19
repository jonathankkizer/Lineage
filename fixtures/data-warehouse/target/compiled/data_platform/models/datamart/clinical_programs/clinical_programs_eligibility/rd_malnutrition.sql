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