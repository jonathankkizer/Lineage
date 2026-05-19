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