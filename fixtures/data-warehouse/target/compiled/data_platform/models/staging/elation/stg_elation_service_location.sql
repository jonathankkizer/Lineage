select
    UQ_SERVICE_LOCATION as uq_service_location,
    ID as service_location_id,
    NAME as service_location_name,
    ADDRESS as address,
    SUITE as suite,
    CITY as city,
    STATE as state,
    ZIP as zip,
    PHONE as phone,
    FAX as fax,
    PRACTICE_ID as practice_id,
    IS_PRIMARY as is_primary,
    CREATION_TIME as creation_datetime,
    CREATED_BY_USER_ID as created_by_user_id,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.service_location