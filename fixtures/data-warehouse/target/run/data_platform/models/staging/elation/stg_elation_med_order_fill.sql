
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_med_order_fill
  
  copy grants
  
  
  as (
    SELECT
    UQ_MED_ORDER_FILL as uq_med_order_fill,
    ID as med_order_fill_id,
    MED_ORDER_ID as med_order_id,
    to_varchar(PATIENT_ID) as elation_id,
    MEDICATION_ID  as medication_id,
    MEDICATION_NAME as medication_name,
    MEDICATION_ROUTE as medication_route,
    MEDICATION_STRENGTH as medication_strength,
    CONTROLLED as controlled,
    QUANTITY as quantity,
    QUANTITY_UNIT as quantity_unit,
    QUANTITY_NOTE as quantity_note,
    MEDICATION_DESCRIPTION as medication_description,
    to_number(DAYS_SUPPLY) as days_supply,
    date(LAST_FILL_DATE) as last_fill_date,
    date(WRITTEN_DATE) as written_date,
    PHARMACY_NCPDPID as pharmacy_ncpdpid,
    PHARMACY_NAME as pharmacy_name,
    PHARMACY_ADDRESS_LINE1 as pharmacy_address_line1,
    PHARMACY_ADDRESS_LINE2 as pharmacy_address_line2,
    PHARMACY_CITY as pharmacy_city,
    PHARMACY_STATE  as pharmacy_state,
    PHARMACY_ZIP  as pharmacy_zip,
    PHARMACY_PHONE_PRIMARY  as pharmacy_phone_primary,
    PHARMACY_NPI  as pharmacy_npi,
    PRESCRIBER_ID as prescriber_id ,
    PRIOR_AUTH as prior_auth,
    ACTIVE as active,
    FUZZINESS as fuzziness,
    IS_DELETED as is_deleted,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync
 from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.med_order_fill
  );

