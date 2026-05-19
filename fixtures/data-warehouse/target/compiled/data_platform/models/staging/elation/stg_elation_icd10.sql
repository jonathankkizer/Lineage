select
    UQ_ICD10 as uq_icd10,
    ID as icd10_id,
    CODE as code,
    DESCRIPTION as code_description,
    IMO_ID as imo_id,
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.ICD10