select 
    UQ_DISCONTINUED_MED_ORDER as uq_discontinued_med_order,
    ID as discontinued_med_order_id,
    to_varchar(PATIENT_ID) as patient_id,
    PRACTICE_ID as practice_id,
    PRESCRIBING_USER_ID as prescriber_user_id,
    MED_ORDER_ID as med_order_id,
    DISCONTINUE_DATE as discontinue_date,
    REASON as reason,
    IS_DOCUMENTED as is_documented,
    MEDICATION_ID as medication_id,
    LAST_MODIFIED as last_modified_datetime,
    CREATION_TIME as creation_datetime,
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
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.discontinue_med_order