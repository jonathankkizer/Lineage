
  create or replace   view dw_dev.dev_jkizer_staging.stg_closedloop_model_unplanned_predictions
  
  copy grants
  
  
  as (
    select
    patient_id as suvida_id,
    date(indexdate) as index_date,
    prediction,
    percentile,
    case
        when percentile >= 95 then 'Level 5'
        when percentile >= 80 then 'Level 4'
        when percentile >= 60 then 'Level 3'
        when percentile >= 40 then 'Level 2'
        else 'Level 1'
    end as risk_level,
    run_datetime
from source_prod.closedloop.src_model_unplanned_predictions
  );

