select
    UQ_OFFICE_MESSAGES_RECIPIENTS as uq_office_messages_recipients,
    ID as office_messages_recipients_id,
    THREAD_ID as thread_id,
    SENT_TO as sent_to,
    STAFF_GROUP_ID as staff_group_id,
    STAFF_GROUP_NAME as staff_group_name,
    STATUS as status,
    ACK_TIME as ack_datetime,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    REMOVED_FROM_THREAD,
    Removed_at,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.office_messages_recipients