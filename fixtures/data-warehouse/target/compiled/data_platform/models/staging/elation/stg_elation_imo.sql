select
    UQ_ID as uq_id,
    IMO_CODE as imo_code,
    DESCRIPTION as imo_description,
    SNOMED_ID as snomed_id,
    IS_DELETED as is_deleted,
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by IMO_CODE order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.imo