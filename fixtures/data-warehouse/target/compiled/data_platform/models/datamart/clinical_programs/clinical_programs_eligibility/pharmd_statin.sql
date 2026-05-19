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