
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_vn2_structured_data
  
  copy grants
  
  
  as (
    select
    ID as structured_data_id,
    VERSIONED_CUSTOM_BLOCK_ID as versioned_custom_block_id,
    EL8_NOTE_ID as el8_note_id,
    PRACTICE_ID as practice_id,
    QUESTION_ID as question_id,
    VISIBLE as is_visible,
    FIELD_NAME as field_name,
    FIELD_VALUE as field_value,
    CREATED_AT as created_at,
    EDITED_AT as edited_at,
    DELETED_AT as deleted_at,
    IS_DELETED as is_deleted,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.elation_note_structured_data
group by all
  );

