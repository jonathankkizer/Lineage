select
    UQ_PATIENT_HCC as uq_patient_hcc,
    ID as patient_hcc_id,
    to_varchar(PATIENT_ID) as patient_id,
    IS_CURRENT as is_current,
    COMMUNITY as community,
    INSTITUTIONAL as institutional,
    VALID_SINCE as valid_since_datetime,
    -- VALID_TILL as valid_till,
    COMMUNITY_2017 as community_2017,
    INSTITUTIONAL_2017 as institutional_2017,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx,
    LAST_CALCULATED as last_calculated_datetime
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_hcc