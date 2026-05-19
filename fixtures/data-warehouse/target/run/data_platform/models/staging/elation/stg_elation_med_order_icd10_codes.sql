
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_med_order_icd10_codes
  
  copy grants
  
  
  as (
    select
    UQ_MED_ORDER_ICD10_CODES as uq_med_order_icd10_codes,
    ID as med_order_icd10_codes_id,
    MED_ORDER_ID as med_order_id,
    ICD10_CODE as icd10_code,
    SEQNO as seqno,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.med_order_icd10_codes
  );

