
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_drug_intolerance_rxnorm
  
  copy grants
  
  
  as (
    select
    UQ_PATIENT_DRUG_INTOLERANCE_RXNORM as uq_patient_drug_intolerance_rxnorm,
    INTOLERANCE_ID as intolerance_id,
    CUI as cui,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by INTOLERANCE_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_drug_intolerance_rxnorm
  );

