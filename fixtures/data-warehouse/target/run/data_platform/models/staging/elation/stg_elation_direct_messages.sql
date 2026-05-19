
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_direct_messages
  
  copy grants
  
  
  as (
    select
    UQ_DIRECT_MESSAGES as uq_direct_messages,	
    ID as direct_messages_id,
    FROM_ADDRESS as from_address,	
    TO_ADDRESS	as to_address,
    SUBJECT as subject,	
    MESSAGE as message,	
    to_varchar(PATIENT_ID) as patient_id,
    PRACTICE_ID as practice_id,	
    TO_USER_ID as to_user_id,
    STATE as state,	
    TIME_SENT as datetime_sent,	
    TIME_COMPLETED as datetime_completed,
    FROM_USER_ID as from_user_id,	
    TO_PHYSICIAN_ID as to_physician_id,	
    CREATION_TIME as creation_datetime,	
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime, 
    DELETED_BY_USER_ID as deleted_by_user_id,	
    SIGNED_TIME as signed_datetime,
    SIGNED_BY_USER_ID as signed_by_user_id,
    DIRECTION as direction,
    --WAREHOUSE_ID	
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.direct_messages
  );

