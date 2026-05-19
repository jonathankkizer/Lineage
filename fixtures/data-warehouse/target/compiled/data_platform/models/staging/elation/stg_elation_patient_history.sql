select
    UQ_PATIENT_HISTORY as uq_patient_history,
    ID as patient_history_id,
    RELATIONSHIP_TYPE as history_value_relationship_type,
    to_varchar(PATIENT_ID) as patient_id,
    VALUE as history_value,
    TYPE as history_type,
    RANK as history_value_rank,
    ICD9_ID as icd9_id,	
    SNOMED_ID as snomed_id,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx,
    'Elation' as source
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_history