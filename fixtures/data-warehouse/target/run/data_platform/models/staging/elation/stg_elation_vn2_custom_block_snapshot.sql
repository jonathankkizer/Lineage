
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_vn2_custom_block_snapshot
  
  copy grants
  
  
  as (
    select
    ID as custom_block_snapshot_id,
    CUSTOM_BLOCK_ID as custom_block_id,
    PRACTICE_ID as practice_id,
    CUSTOM_BLOCK_SNAPSHOT as custom_block_snapshot,
    CREATED_AT as created_at,
    EDITED_AT as edited_at,
    DELETED_AT as deleted_at,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.elation_note_custom_block_snapshot
group by all
  );

