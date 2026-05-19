
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_problem_code
  
  copy grants
  
  
  as (
    select
    UQ_PATIENT_PROBLEM_CODE as uq_patient_problem_code,
    PATIENT_PROBLEM_ID as patient_problem_id,
    IMO_CODE as imo_code,
    ICD10_ID as icd10,
    ICD9_ID as icd9_id,
    SNOMED_ID as snomed_id,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by PATIENT_PROBLEM_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_problem_code
  );

