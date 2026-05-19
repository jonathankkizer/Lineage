
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_br_report_document_tag
  
  copy grants
  
  
  as (
    select
	UQ_REPORT_DOCUMENT_TAG as uq_report_document_tag_id,
	REPORT_ID as report_id,
	DOCUMENT_TAG_ID as document_tag_id,
	'Elation' as source,
	row_number() over (partition by UQ_REPORT_DOCUMENT_TAG order by HDB_LAST_SYNC desc) as _rn -- 1 will be most recent record per ID
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.report_document_tag
where IS_DELETED = 'false'
  );

