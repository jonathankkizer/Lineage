
  
    

create or replace transient table dw_dev.dev_jkizer.patient_clinical_assessment
    copy grants
    
    
    as (with date_spine as (
    select
        date_month as date_month_start,
        last_day(date_month) as date_month_end,
    from dw_dev.dev_jkizer.dim_date
    where (date_month_start <= current_date())
    and (is_bom = TRUE)
),
mh_values as (
    select
        ds.date_month_start,
        ds.date_month_end,
        fph.suvida_id,
        date(fph.creation_datetime) as test_date,
        fph.creation_datetime as test_datetime,
        history_type as test_type,
        history_value as test_value,
        history_value_numeric as test_value_numeric,
        case when date_month_start = date_trunc(month, current_date()) then 1 else 0 end as is_current_month,
        row_number() over (partition by suvida_id, history_type order by test_datetime asc) as test_number
    from date_spine ds 
    join dw_dev.dev_jkizer.fct_patient_history fph
        on date(fph.creation_datetime) between ds.date_month_start and ds.date_month_end
    where 
        (history_value is not null or history_value_numeric is not null)
    qualify 
        fph.creation_datetime is null or    -- in the event of no test values in a month, this keeps both rows for said monthand patient and nulls them
            row_number() over(partition by suvida_id, history_type, test_datetime order by test_datetime) = 1
)
select
    date_month_start,
    date_month_end,
    suvida_id,
    is_current_month,
    test_date,
    test_datetime,
    test_type,
    test_value,
    test_value_numeric,
    test_number
from mh_values
    )
;


  