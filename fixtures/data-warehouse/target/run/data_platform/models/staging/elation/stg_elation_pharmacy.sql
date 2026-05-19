
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_pharmacy
  
  copy grants
  
  
  as (
    select
    UQ_PHARMACY as uq_pharmacy,
    NCPDPID as ncpdp_id,
    STORE_NAME as store_name,
    ADDRESS_LINE1 as address_line1,
    ADDRESS_LINE2 as address_line2,
    CITY as city,
    STATE as state,
    left(ZIP, 5) as zip,
    PHONE_PRIMARY as phone_primary,
    FAX as fax,
    EMAIL as email,
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by NCPDPID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.pharmacy
  );

