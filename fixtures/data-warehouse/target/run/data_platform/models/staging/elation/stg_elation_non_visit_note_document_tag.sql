
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_non_visit_note_document_tag
  
  copy grants
  
  
  as (
    select
    UQ_NON_VISIT_NOTE_DOCUMENT_TAG as uq_non_visit_note_document_tag,
    NON_VISIT_NOTE_ID as non_visit_note_id,
    DOCUMENT_TAG_ID as document_tag_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by NON_VISIT_NOTE_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.non_visit_note_document_tag
  );

