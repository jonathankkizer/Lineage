
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_allergy_rxnorm
  
  copy grants
  
  
  as (
    select
    UQ_PATIENT_ALLERGY_RXNORM as uq_patient_allergy_rxnorm,
    ALLERGY_ID as allergy_id,
    CUI as cui,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ALLERGY_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_allergy_rxnorm
  );

