select
    UQ_PATIENT_PHONE as uq_patient_phone,
    ID as patient_phone_id,
    to_varchar(PATIENT_ID) as patient_id,
    
    
    case
        when regexp_replace(PHONE, '[^0-9]', '') = '' then null
        when length(regexp_replace(PHONE, '[^0-9]', '')) = 11
            and left(regexp_replace(PHONE, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(PHONE, '[^0-9]', ''), 10)
        when length(regexp_replace(PHONE, '[^0-9]', '')) = 10
            then regexp_replace(PHONE, '[^0-9]', '')
        else null
    end
 as phone,
    PHONE_TYPE as phone_type,
    LAST_MODIFIED as last_modified_datetime,
    IS_DELETED as _is_deleted_record,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx,
    row_number() over (partition by patient_id order by is_deleted, id asc) as phone_priority_ranking, -- 1 = primary, 2 = secondary, etc. Rank deleted records last
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_phone