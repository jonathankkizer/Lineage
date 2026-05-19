
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_health_maintenance
  
  copy grants
  
  
  as (
    select
    UQ_HEALTH_MAINTENANCE as uq_health_maintenance,
    ID as health_maintenance_id,
    to_varchar(PATIENT_ID) as patient_id, 
    CONFIDENTIAL as confidential,
    DATE as health_maintenance_date,
    NOTE as note,
    NAME as health_maintenance_name,
    MEASURE_CODE as measure_code,
    ABNORMAL_RESULT as abnormal_result,
    NORMAL_RESULT as normal_result,
    DOC_TAG_ID as doc_tag_id,
    LAB_REPORT_ID as lab_report_id,
    PHYSICIAN_ID as physician_id,
    FIRSTNAME as physician_first_name,
    LASTNAME as physician_last_name,
    CREATED_DATE as created_datetime,
    DELETED_DATE as deleted_datetime,
    --WAREHOUSE_ID
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by ID order by HDB_LAST_SYNC desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.health_maintenance
  );

