
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_user
  
  copy grants
  
  
  as (
    select
	UQ_USER as uq_user,
	ID as user_id,
	EMAIL as user_email,
	to_boolean(case when IS_ACTIVE = 'True' then 1 else 0 end) as is_active,
	PRACTICE_ID as practice_id,
	concat(FIRST_NAME, ' ', LAST_NAME) as user_name,
	FIRST_NAME as user_first_name,
	LAST_NAME as user_last_name,
	split(LAST_NAME, ',')[1]::string as elation_team,
	to_boolean(case when IS_PRACTICE_ADMIN = 'True' then 1 else 0 end) as is_practice_admin,
	USER_TYPE as user_type,
	OFFICE_STAFF_ID as office_staff_id,
	PHYSICIAN_ID as physician_id,
	SPECIALTY as specialty_desc,
	CREDENTIALS as credentials,
	NPI as npi,
	TIN as tin,
	to_boolean(case when VERIFIED = 'True' then 1 else 0 end) as is_verified,
	CANONICAL_PHYSICIAN_ID as canonical_physician_id,
	--WAREHOUSE_ID,
	HDB_LAST_SYNC as hdb_last_sync_datetime,
	date(HDB_LAST_SYNC) as _last_sync_date,
	row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.user
  );

