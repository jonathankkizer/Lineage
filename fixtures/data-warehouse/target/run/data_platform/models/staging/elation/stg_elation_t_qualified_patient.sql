
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_t_qualified_patient
  
  copy grants
  
  
  as (
    select
    UQ_TQ_PATIENT as uq_t_qualified_patient,
    ID as t_qualified_patient_id,
    PRACTICE_ID as practice_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.t_qualified_patient
  );

