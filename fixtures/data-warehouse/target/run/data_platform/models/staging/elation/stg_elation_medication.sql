
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_medication
  
  copy grants
  
  
  as (
    select
    UQ_MEDICATION as uq_medication,
    ID as medication_id,
    PRACTICE_CREATED_ID as practice_created_id,
    DISPLAY_NAME as display_name,
    ROUTE as route,
    STRENGTH as strength,
    BRAND_NAME as brand_name,
    GENERIC_NAME as generic_name,
    FORM as form,
    TYPE as type,
    CONTROLLED as controlled,
    DEA_DESCRIPTION as dea_description,
    IS_DRUG as is_drug,
    BRAND_TYPE as brand_type,
    IS_MAINTENANCE_DRUG as is_maintenance_drug,
    CREATION_TYPE as creation_type,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.medication
  );

