
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_care_flows
  
  copy grants
  
  
  as (
    select 
    id as care_flow_id,
    patient_id,
    definition_id,
    title,
    release_id,
    status,
    date(start_date) as care_flow_start_date,
    date(stop_date) as care_flow_stop_date,
    date(complete_date) as care_flow_completed_date,
    date(last_synced_at) as last_synced_at
from source_prod.awell.care_flows
  );

