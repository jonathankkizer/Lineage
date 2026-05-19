select
	uq_referral_order_dx,
	id as referral_diagnosis_id,
	icd10code_id as icd_10_code_id,
	referralorder_id as referral_id,
	warehouse_id,
	is_deleted,
	HDB_LAST_SYNC as hdb_last_sync_datetime,
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.referral_order_dx