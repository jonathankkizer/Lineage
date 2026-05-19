
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_vn2_question
  
  copy grants
  
  
  as (
    select
    ID as question_id,
    PRACTICE_ID as practice_id,
    FIELD_NAME as field_name,
    QUESTION_TYPE as question_type,
    QUESTION_TEXT as question_text,
    REQUIRED as is_required,
    CREATED_AT as created_at,
    EDITED_AT as edited_at,
    DELETED_AT as deleted_at,
    IS_DELETED as is_deleted,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.elation_note_question
group by all
  );

