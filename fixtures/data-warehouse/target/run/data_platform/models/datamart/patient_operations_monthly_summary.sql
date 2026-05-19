
  
    

create or replace transient table dw_dev.dev_jkizer.patient_operations_monthly_summary
    copy grants
    
    
    as (select
    pa.observation_month as date_month,
    pa.suvida_id,
    pa.provider_name,
    pa.location_name,
    max(pa.visit_in_90_days) as visit_in_90_days,
    max(pa.awv_in_90_days) as awv_in_90_days,
    max(pa.visit_in_60_days) as visit_in_60_days,
    max(pa.awv_in_60_days) as awv_in_60_days,
    max(pa.visit_completed) as visit_completed,
    max(pa.awv_completed) as awv_completed,
    max(pa.tcm_completed) as tcm_completed,
    max(last_visit_within_90_days) as last_visit_within_90_days,
    max(pa.engaged_status) as engaged_status
from dw_dev.dev_jkizer.patient_visit_summary_month pa
group by pa.observation_month, pa.suvida_id, pa.provider_name, pa.location_name
    )
;


  