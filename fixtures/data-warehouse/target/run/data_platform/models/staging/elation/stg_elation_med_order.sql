
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_med_order
  
  copy grants
  
  
  as (
    SELECT  
    UQ_MED_ORDER as uq_med_order,
    ID as med_order_id,
    to_varchar(PATIENT_ID) as elation_id,
    PRACTICE_ID as practice_id,
    PRESCRIBING_USER_ID as prescribing_user_id,
    TYPE as med_type,
    ROUTE as med_route,
    STRENGTH as strength,
    FORM as form,
    NDC as ndc,
    MEDICATION_ID as medication_id,
    DISPLAYED_MEDICATION_NAME as displayed_medication_name,
    MEDICATION_TYPE as medication_type,
    DIRECTIONS as directions,
    INDICATION as indication,
    QTY as quantity,
    QTY_UNITS as quantity_units,
    DAYS_SUPPLY as prescribed_days_supply,
    AUTH_REFILLS as auth_refills,
    AUTH_REFILLS_QUALIFIER as auth_refills_qualifier,
    date(START_DATE) as med_start_date,
    DOCUMENTING_PERSONNEL_ID as documenting_personnel_id,
    PHARMACY_INSTRUCTIONS as pharmacy_instructions ,
    SUBSTITUTIONS as substitutions,
    ORIGIN as origin,
    NOTES as notes,
    PHARMACY_NCPDPID as pharmacy_ncpdpid,
    FULFILLMENT_TYPE as fulfillment_type,
    MED_ORDER_THREAD_ID as med_order_thread_id,
    LAST_MODIFIED as last_modified,
    date(CREATION_TIME) as creation_date,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    date(DELETION_TIME) as deletion_date,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    date(SIGNED_TIME) as signed_date,
    SIGNED_TIME as signed_datetime,
    SIGNED_BY_USER_ID as signed_by_user_id,
    FROM_PLR as from_plr,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync,
    'Elation' as source
 from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.med_order
  );

