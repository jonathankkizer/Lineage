
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_external_patient_id
  
  copy grants
  
  
  as (
    select
    UQ_EXTERNAL_PATIENT_ID as uq_external_patient_id,
    ID as id,
    EXTERNAL_SYSTEM as external_system,
    EXTERNAL_PATIENT_ID as external_patient_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    MASTER_ID as master_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.external_patient_id
  );

