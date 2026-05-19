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