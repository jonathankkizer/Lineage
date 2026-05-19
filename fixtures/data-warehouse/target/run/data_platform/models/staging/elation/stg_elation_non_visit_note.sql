
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_non_visit_note
  
  copy grants
  
  
  as (
    select
    nvn.UQ_NON_VISIT_NOTE as uq_non_visit_note,
    nvn.ID as non_visit_note_id,
    to_varchar(nvn.PATIENT_ID) as elation_id,
    nvn.PRACTICE_ID as practice_id,
    nvn.NOTE_TYPE as note_type,
    date(nvn.DOCUMENT_DATE) as document_date,
    to_timestamp(nvn.DOCUMENT_DATE) as document_datetime,
    date(nvn.CHART_FEED_DATE) as chart_feed_date,
    nvn.CHART_FEED_DATE as chart_feed_datetime,
    date(nvn.LAST_MODIFIED) as last_modified_date,
    nvn.LAST_MODIFIED as last_modified_datetime,
    date(nvn.CREATION_TIME) as creation_date,
    nvn.CREATION_TIME as creation_datetime,
    nvn.CREATED_BY_USER_ID as created_by_user_id,
    date(nvn.DELETION_TIME) as deletion_date,
    nvn.DELETION_TIME as deletion_datetime,
    nvn.DELETED_BY_USER_ID as deleted_by_user_id,
    date(nvn.SIGNED_TIME) as signed_date,
    nvn.SIGNED_TIME as signed_datetime,
    nvn.SIGNED_BY_USER_ID as signed_by_user_id,
    nvn.FROM_PLR as from_plr,
    nvn.WAREHOUSE_ID as warehouse_id,
    nvn.HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(nvn.HDB_LAST_SYNC) as hdb_last_sync,
    sep._is_test_patient
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.non_visit_note nvn
left join dw_dev.dev_jkizer_staging.stg_elation_patient sep 
    on nvn.PATIENT_ID = sep.elation_id
    and sep._idx = 1
  );

