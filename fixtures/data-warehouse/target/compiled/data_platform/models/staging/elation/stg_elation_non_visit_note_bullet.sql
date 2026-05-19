SELECT 
  UQ_NON_VISIT_NOTE_BULLET as uq_non_visit_note_bullet
  ,ID as non_visit_note_bullet_id
  ,NON_VISIT_NOTE_ID as non_visit_note_id
  ,SEQUENCE as sequence
  ,REPLACE(REPLACE(TEXT, CHAR(13), ' - '), CHAR(10), ' - ') as text
  ,IS_DELETED as is_deleted
  ,WAREHOUSE_ID as warehouse_id
  ,HDB_LAST_SYNC as hdb_last_sync_datetime
  ,date(HDB_LAST_SYNC) as hdb_last_sync
FROM elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.non_visit_note_bullet