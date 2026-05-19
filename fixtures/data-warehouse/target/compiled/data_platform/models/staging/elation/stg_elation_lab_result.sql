SELECT 
  UQ_LAB_RESULT as uq_lab_result
  ,ID as lab_result_id
  ,LAB_REPORT_ID as lab_report_id
  ,date(COLLECTED_DATE) as collected_date
  ,to_timestamp(collected_date) as collected_date_time
  ,RESULTED_DATE as resulted_datetime
  ,date(RESULTED_DATE) as resulted_date
  ,ACCESSION_NUMBER as accession_number
  ,ACCESSION_STATUS as accession_status
  ,TEST_CATEGORY as test_category
  ,TEST_NAME as test_name
  ,TEST_STATUS as test_status
  ,VALUE as test_value
  ,UNITS as units
  ,VALUE_TYPE as value_type
  ,REFERENCE_MIN as reference_min
  ,REFERENCE_MAX as reference_max
  ,IS_ABNORMAL as is_abnormal
  ,ABNORMAL_FLAG as abnormal_flag
  ,REPORT_TEXT as report_text
  ,VALUE_NOTE as value_note
  ,NOTE as note
  ,LOINC as loinc
  ,IS_DELETED as is_deleted
  ,WAREHOUSE_ID as warehouse_id
  ,HDB_LAST_SYNC as hdb_last_sync
 FROM elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.lab_result