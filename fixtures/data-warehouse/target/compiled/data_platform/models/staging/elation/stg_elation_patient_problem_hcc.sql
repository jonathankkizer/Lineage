select
    UQ_PATIENT_PROBLEM_CODE_HCC as uq_patient_problem_code_hcc,
    VERSION as version,
    ICD10_ID as icd10_id,
    HCC_CODE as hcc_code,
    HCC_LABEL as hcc_label,
    HCC_COMMUNITY_FACTOR as hcc_community_factor,
    HCC_INSTITUTIONAL_FACTOR as hcc_institutional_factor,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ICD10_ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient_problem_code_hcc