
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_master_patient
  
  copy grants
  
  
  as (
    select
    UQ_MASTER_PATIENT as uq_master_patient,
    ID as master_patient_id,
    -- CANONICAL_PHYSICIAN_ID as canonical_physician_id,
    PRIMARY_CARE_PROVIDER_ID as primary_care_provider_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.master_patient
  );

