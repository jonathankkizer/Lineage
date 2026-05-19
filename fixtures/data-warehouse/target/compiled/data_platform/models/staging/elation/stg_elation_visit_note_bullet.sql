select
    UQ_VISIT_NOTE_BULLET as uq_visit_note_bullet,
    ID as visit_note_bullet_id,
    VISIT_NOTE_ID as visit_note_id,
    PARENT_BULLET_ID as parent_bullet_id,
    FROM_AMENDMENT as from_amendment,
    CATEGORY as category,
    SEQUENCE as sequence,
    TEXT as text,
    REPLACED_BY_VISIT_NOTE_BULLET_ID as replaced_by_visit_note_bullet_id,
    LAST_MODIFIED as last_modified_datetime,
    DELETED_DATE as deleted_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    VISIT_NOTE_DELETION_TIME as visit_note_deletion_datetime,
    VISIT_NOTE_DELETED_BY_USER_ID as visit_note_deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.visit_note_bullet