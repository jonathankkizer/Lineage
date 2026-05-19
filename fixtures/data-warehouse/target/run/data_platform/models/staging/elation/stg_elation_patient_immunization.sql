
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_immunization
  
  copy grants
  
  
  as (
    select
    UQ_PATIENT_IMMUNIZATION as uq_patient_immunization,
    ID as patient_immunization_id,
    to_varchar(PATIENT_ID) as patient_id,
    CVX as cvx,
    NAME as immunization_name,
    ADMINISTERING_PHYSICIAN_ID as administering_physician_id,
    DESCRIPTION as description,
    to_timestamp(ADMINISTERED_DATE) as administered_datetime,
    QTY as qty,
    QTY_UNITS as qty_units,
    LOT_NUMBER as lot_number,
    MANUFACTURER_NAME as manufacturer_name,
    REASON as reason,
    EXPIRATION_DATE as expiration_date,
    VIS as vis,
    METHOD as method,
    SITE as site, 
    NOTES as notes,
    ORDERING_PHYSICIAN_ID as ordering_physician_id,
    PUBLICITY_CODE as publicity_code,
    VFC_ELIGIBILITY as vfc_eligibility,
    INFO_SOURCE as info_source,
    ALLOWED_SHARING as allowed_sharing,
    to_timestamp(LAST_MODIFIED) as last_modified_datetime,
    to_timestamp(CREATION_TIME) as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    to_timestamp(DELETION_TIME) as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    to_timestamp(HDB_LAST_SYNC) as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_immunization
  );

