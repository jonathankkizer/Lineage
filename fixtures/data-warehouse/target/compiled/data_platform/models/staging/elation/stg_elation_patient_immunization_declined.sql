select
    UQ_PATIENT_IMMUNIZATION_DECLINED as uq_patient_immunization_declined,
    ID as patient_immunization_declined_id,
    to_varchar(PATIENT_ID) as patient_id,
    CDC_TYPE as cdc_type,
    DECLINED_DATE as declined_datetime,
    DECLINED_REASON as declined_reason,
    IMMUNITY as immunity,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_immunization_declined