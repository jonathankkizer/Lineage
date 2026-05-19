select
    VISIT_NOTE_ID as visit_note_id,
    EL8_NOTE_ID as el8_note_id,
    PRACTICE_ID as practice_id,
    PATIENT_ID as patient_id,
    CUSTOM_BLOCK_SNAPSHOT_ID as custom_block_snapshot_id,
    QUESTION_ID as question_id,
    FIELD_NAME as field_name,
    QUESTION_TYPE as question_type,
    QUESTION_TEXT as question_text,
    RESPONSE as response,
    REQUIRED as is_required,
    IS_VISIBLE as is_visible,
    WAREHOUSE_ID as warehouse_id,
    IS_DELETED as is_deleted,
    HDB_LAST_SYNC as hdb_last_sync
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.elation_note
group by all