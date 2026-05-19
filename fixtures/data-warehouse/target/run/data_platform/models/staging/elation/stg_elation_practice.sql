
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_practice
  
  copy grants
  
  
  as (
    select
    UQ_PRACTICE as uq_practice,
    ID as id,
    NAME as name,
    ADDRESS_LINE1 as address_line1,
    ADDRESS_LINE2 as address_line2,
    CITY as city,
    STATE as state,
    ZIP as zip,
    PHONE as phone,
    FAX as fax,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.practice
  );

