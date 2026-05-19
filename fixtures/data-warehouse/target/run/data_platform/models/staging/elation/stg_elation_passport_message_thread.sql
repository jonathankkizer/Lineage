
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_passport_message_thread
  
  copy grants
  
  
  as (
    select
    UQ_PASSPORT_MESSAGE_THREAD as uq_passport_message_thread,
    ID as passport_message_thread_id,
    PASSPORT_ID as passport_id,
    MESSAGE as message,
    SENT_FROM as sent_from,
    USER_TYPE as user_type,
    USER_ID	as user_id,
    MESSAGE_THREAD_CREATION_TIME as message_thread_creation_datetime,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    SIGNED_TIME as signed_datetime,
    SIGNED_BY_USER_ID as signed_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.passport_message_thread
  );

