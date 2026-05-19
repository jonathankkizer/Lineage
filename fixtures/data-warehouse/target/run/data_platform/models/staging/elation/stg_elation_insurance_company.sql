
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_insurance_company
  
  copy grants
  
  
  as (
    select
    UQ_INSURANCE_COMPANY as uq_insurance_company,
    ic.ID as insurance_company_id,
    ic.ADDRESS as insurance_company_address,
    ic.SUITE as suite,
    ic.CITY as city,
    ic.STATE as state,
    ic.ZIP as zip,
    ic.PHONE as phone,
    ic.CARRIER as carrier,
    ic.EXTENSION as extension,
    PRACTICE_ID as practice_id,
    ENTERPRISE_ID as enterprise_id,
    COUNTY_CODE as county_code,
    ics.payer_id,
    ics.eligibility_payer_id,
    ics.aliases,
    insurance_type,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deleted_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ic.ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.insurance_company ic
left join source_prod.misc.src_ehd_insurance_companies ics 
    on ic.ID = ics.ID
  );

