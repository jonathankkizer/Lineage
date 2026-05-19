
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_provider_letter
  
  copy grants
  
  
  as (
    select
    UQ_PROVIDER_LETTER as uq_provider_letter,
    ID as provider_letter_id,
    to_varchar(PATIENT_ID) as patient_id,
    PRACTICE_ID as practice_id,
    SEND_TO_NAME as send_to_name,
    SUBJECT as subject,
    BODY as body,
    EMAIL_TO as email_to,
    DELIVERY_METHOD as delivery_method,
    DELIVERY_DATE as delivery_date,
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
    to_timestamp(DOCUMENT_DATE) as document_datetime,
    CHART_FEED_DATE as chart_feed_datetime,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_time,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    SIGNED_TIME as signed_datetime,
    SIGNED_BY_USER_ID as signed_by_user_id,
    FROM_PLR as from_plr,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.provider_letter
  );

