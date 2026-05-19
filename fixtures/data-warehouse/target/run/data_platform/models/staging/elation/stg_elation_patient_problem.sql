
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_problem
  
  copy grants
  
  
  as (
    select
    UQ_PATIENT_PROBLEM as uq_patient_problem,
    ID as patient_problem_id,
    to_varchar(PATIENT_ID) as patient_id,
    DESCRIPTION as problem_description,
    RANK as rank,
    START_DATE as start_date,
    RESOLVED_DATE as resolved_date,
    STATUS as status,
    SYNOPSIS as synopsis,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_problem
  );

