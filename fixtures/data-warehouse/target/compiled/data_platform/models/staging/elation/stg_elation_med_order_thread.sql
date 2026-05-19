select
    UQ_MED_ORDER_THREAD as uq_med_order_thread,
    ID as med_order_thread_id,
    to_varchar(PATIENT_ID) as patient_id,
    PRACTICE_ID as practice_id,
    IS_PERMANENT as is_permanent,
    DISCONTINUE_ORDER_ID as discontinue_order_id,
    LATEST_MED_ORDER_ID as latest_med_order_id,
    START_DATE as start_date,
    to_timestamp(DOCUMENT_DATE) as document_datetime,
    MANUAL_START_DATE as manual_start_date,
    SHAREABLE as shareable,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.med_order_thread