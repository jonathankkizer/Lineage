with risk_strat_models as (
select 
    suvida_id,
    'unplanned_admission' as model_type,
    index_date,
    run_datetime, 
    prediction,
    percentile,
    risk_level
from dw_dev.dev_jkizer_staging.stg_closedloop_model_unplanned_predictions
union all
select
    suvida_id,
    'readmission' as model_type,
    index_date,
    run_datetime, 
    prediction,
    percentile,
    risk_level
from dw_dev.dev_jkizer_staging.stg_closedloop_model_readmissions_predictions
union all
select
    suvida_id,
    'mortality' as model_type,
    index_date,
    run_datetime, 
    prediction,
    percentile,
    risk_level
from dw_dev.dev_jkizer_staging.stg_closedloop_model_mortality_predictions
union all
select
    suvida_id,
    'ed_utilizer' as model_type,
    index_date,
    run_datetime, 
    prediction,
    percentile,
    risk_level
from dw_dev.dev_jkizer_staging.stg_closedloop_model_ed_utilizers_predictions
union all
select
    suvida_id,
    'dialysis' as model_type,
    index_date,
    run_datetime, 
    prediction,
    percentile,
    risk_level
from dw_dev.dev_jkizer_staging.stg_closedloop_model_dialysis_predictions
)
select 
    suvida_id,
    model_type,
    index_date as closed_loop_run_date,
    run_datetime,
    prediction,
    percentile,
    risk_level,
    row_number() over (partition by suvida_id, model_type order by run_datetime desc) as model_run_order
from risk_strat_models