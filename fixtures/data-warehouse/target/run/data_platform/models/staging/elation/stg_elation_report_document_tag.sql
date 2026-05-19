
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_report_document_tag
  
  copy grants
  
  
  as (
    select
    UQ_REPORT_DOCUMENT_TAG as uq_report_document_tag,
    REPORT_ID as report_id,
    DOCUMENT_TAG_ID as document_tag_id,
    IS_DELETED as is_deleted,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by DOCUMENT_TAG_ID order by HDB_LAST_SYNC desc) as _idx,
    'Elation' as source
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.report_document_tag
  );

