select
    UQ_REPORT_ADDENDUM as uq_report_addendum,
    ID as report_addendum_id,
    REPORT_ID as report_id,
    TEXT as text,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx,
    'Elation' as source
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.report_addendum