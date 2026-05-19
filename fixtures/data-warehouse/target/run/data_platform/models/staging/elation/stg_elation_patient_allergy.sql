
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_allergy
  
  copy grants
  
  
  as (
    select
    UQ_PATIENT_ALLERGY as uq_patient_allergy,
    ID as patient_allergy_id,
    to_varchar(PATIENT_ID) as patient_id,
    REACTION as reaction,
    STATUS as status,
    START_DATE as starting_date,
    NAME as name,
    ALLERGEN_TYPE as allergen_type,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_allergy
  );

