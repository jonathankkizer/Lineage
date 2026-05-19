
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_bill_item_diagnosis
  
  copy grants
  
  
  as (
    select
	UQ_BILL_ITEM_DX as uq_bill_item_dx,
	BILL_ITEM_ID as bill_item_id,
	SEQNO as bill_item_diagnosis_sequence_no,
	ICD9_CODE as icd_9_code,
	trim(replace(ICD10_CODE, '.', '')) as icd_10_code,
	DX as diagnosis,
	to_boolean(case when (BILL_ITEM_DELETION_TIME is not null or DELETELOG_ID is not null) then 1 else 0 end) as _is_deleted_record,
	-- date(BILL_ITEM_DELETION_TIME) as bill_item_deletion_date, -- not always populated even if record is deleted
	--DELETELOG_ID
	--WAREHOUSE_ID
	HDB_LAST_SYNC as hdb_last_sync_datetime,
	date(HDB_LAST_SYNC) as _last_sync_date,
	row_number() over (partition by UQ_BILL_ITEM_DX order by date(HDB_LAST_SYNC) desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.bill_item_dx
  );

