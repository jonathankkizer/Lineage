select
    UQ_OFFICE_MESSAGES as uq_office_messages,
    ID as office_messages_id,
    to_varchar(PATIENT_ID) as elation_id,
    THREAD_ID as thread_id,
    TEXT as text,
    DATE_SENT datetime_sent,
    URGENT as urgent,
    SENDER_ID as sender_id,
    POST_DATE as post_datetime,
    CREATION_TIME creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    SIGNED_TIME as signed_datetime,
    SIGNED_BY_USER_ID as signed_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.office_messages