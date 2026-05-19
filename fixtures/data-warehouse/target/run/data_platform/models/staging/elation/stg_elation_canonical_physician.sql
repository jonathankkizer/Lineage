
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_canonical_physician
  
  copy grants
  
  
  as (
    select
    UQ_CANONICAL_PHYSICIAN as uq_canonical_physician,
    ID as elation_canonical_physician_id,
    NPI	as npi, 
    FIRST_NAME as first_name,	
    LAST_NAME as last_name,	
    ORG_NAME as organization_name,	
    CREDENTIALS as credentials,
    SPECIALTY as speciality,	
    IS_DELETED as is_deleted,
    --WAREHOUSE_ID	
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
	row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.canonical_physician
  );

