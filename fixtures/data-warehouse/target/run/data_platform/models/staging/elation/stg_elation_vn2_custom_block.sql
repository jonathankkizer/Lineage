
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_vn2_custom_block
  
  copy grants
  
  
  as (
    select
    ID as custom_block_id,
    PRACTICE_ID as practice_id,
    LABEL as label,
    CURRENT_STATE_SNAPSHOT as current_state_snapshot,
    COPIED_FROM_BLOCK_ID as copied_from_block_id,
    CREATED_AT as created_at,
    CREATED_BY_USER_ID as created_by_user_id,
    EDITED_AT as edited_at,
    DELETED_AT as deleted_at,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.elation_note_custom_block
group by all
  );

