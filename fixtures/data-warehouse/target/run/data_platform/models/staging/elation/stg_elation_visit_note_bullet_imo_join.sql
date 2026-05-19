
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet_imo_join
  
  copy grants
  
  
  as (
    select
    UQ_VISITNOTEBULLET_IMO_JOIN as uq_visit_note_bullet_imo_join,
    ID as visit_note_bullet_imo_join_id,
    VISIT_NOTE_BULLET_ID as visit_note_bullet_id,
    IMO_ID as imo_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.visitnotebullet_imo_join
  );

