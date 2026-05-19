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