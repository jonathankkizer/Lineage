
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_referral_order
  
  copy grants
  
  
  as (
    select 
    UQ_REFERRAL_ORDER as uq_referral_order,
    ID as referral_id,
    to_varchar(PATIENT_ID) as elation_id,
    PRACTICE_ID as practice_id,
    SEND_TO_NAME as send_to_name,
    SUBJECT as referral_subject,
    BODY as referral_body_text,
    EMAIL_TO as email_to,
    DELIVERY_METHOD as delivery_method,
    DELIVERY_DATE as delivery_date,
    FAX_STATUS as fax_status,
    PROCESSING_STATUS as processing_status,
    RESOLUTION_STATE as resolution_state,
    --CLINICAL_REASON as clinical_reason, -- removed from HDB 20251219
    BODY as clinical_reason,
    PRESCRIBING_USER_ID as sender_user_id,
    AUTHORIZATION_FOR as authorization_for,
    AUTH_NUMBER as authorization_number,
    RECIPIENT_FIRSTNAME as recipient_first_name,
    RECIPIENT_LASTNAME as recipient_last_name,
    RECIPIENT_MIDDLENAME as recipient_middle_name,
    RECIPIENT_NPI as recipient_npi,
    RECIPIENT_CREDENTIALS as recipient_credentials,
    RECIPIENT_CONTACTTYPE as recipient_contact_type,
    RECIPIENT_ADDRESS as recipient_address,
    RECIPIENT_CITY as recipient_city,
    RECIPIENT_STATE as recipient_state,
    RECIPIENT_ZIP as recipient_zip,
    RECIPIENT_FAX as recipient_fax,
    RECIPIENT_ORG_NAME as recipient_org_name,
    RECIPIENT_SPECIALTY as recipient_specialty,
    FROM_PLR as from_plr,
    IS_DELETED as is_deleted,
    date(DOCUMENT_DATE) as document_date,
    to_timestamp(DOCUMENT_DATE) as document_datetime,
    date(CHART_FEED_DATE) as chart_feed_date,
    CHART_FEED_DATE as chart_feed_datetime,
    date(LAST_MODIFIED) as last_modified_date,
    LAST_MODIFIED as last_modified_datetime,
    date(CREATION_TIME) as creation_date,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    date(DELETION_TIME) as deletion_date,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    date(SIGNED_TIME) as signed_date,
    SIGNED_TIME as signed_datetime,
    SIGNED_BY_USER_ID as signed_by_user_id,
    WAREHOUSE_ID as warehouse_id,
    HDB_LAST_SYNC as hdb_last_sync_datetime,
 FROM elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.referral_order
  );

