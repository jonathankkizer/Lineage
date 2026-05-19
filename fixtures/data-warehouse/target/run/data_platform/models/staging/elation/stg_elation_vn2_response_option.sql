
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_vn2_response_option
  
  copy grants
  
  
  as (
    select
    ID as response_option_id,
    PRACTICE_ID as practice_id,
    QUESTION_ID as question_id,
    RESPONSE_VALUE as response_value,
    RESPONSE_TEXT as response_text,
    CREATED_AT as created_at,
    EDITED_AT as edited_at,
    DELETED_AT as deleted_at,
    IS_DELETED as is_deleted,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.elation_note_response_option
group by all
  );

