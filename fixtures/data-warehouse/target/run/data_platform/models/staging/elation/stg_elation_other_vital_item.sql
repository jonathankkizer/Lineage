
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_other_vital_item
  
  copy grants
  
  
  as (
    select
    UQ_OTHER_VITAL_ITEM as uq_other_vital_item,
    ID as other_vital_item_id,
    VITAL_ID as vital_id,
    RECORD_DATE as record_datetime,
    NAME as name,
    VALUE as value,
    UNITS as units,
    EXTRA_NOTE as extra_note,
    REPLACED_BY_EDIT_ID as replaced_by_edit_id,
    PREVIOUS_VALUE as previous_value,
    PREVIOUS_RECORD_TIME as previous_record_time,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.other_vital_item
  );

