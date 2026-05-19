
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_medication_rxnorm
  
  copy grants
  
  
  as (
    select
    UQ_MEDICATION_RXNORM as uq_medication_rxnorm,
    MEDICATION_ID as medication_id,
    CUI as cui,
    NAME as medication_name,
    DESCRIPTION as medication_description,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by MEDICATION_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.medication_rxnorm
  );

