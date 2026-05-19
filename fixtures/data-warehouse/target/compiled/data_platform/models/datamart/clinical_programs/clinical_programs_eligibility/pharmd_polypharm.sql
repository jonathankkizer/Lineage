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