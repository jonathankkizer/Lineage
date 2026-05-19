
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_lab_order
  
  copy grants
  
  
  as (
    SELECT  
  UQ_LAB_ORDER as uq_lab_order
  ,ID as lab_order_id
  ,REQ_NUMBER as req_number
  ,to_varchar(PATIENT_ID) as elation_id
  ,LAB_VENDOR as lab_vendor
  ,LAB_SITE as lab_site
  ,LAB_CENTER as lab_center
  ,date(DATE_FOR_TEST) as date_for_test
  ,FOLLOW_UP_NOTES as follow_up_notes
  ,ORDER_STATUS as order_status
  ,RESOLVING_DOCUMENT_ID as lab_report_id
  ,ORDERING_PROVIDER as ordering_provider
  ,date(LAST_MODIFIED) as last_modified_date 
  ,to_timestamp(LAST_MODIFIED) as last_modified_datetime
  ,IS_EORDER as is_eorder
  ,PT_COND as pt_cond
  ,STAT as stat
  ,BILL_TYPE as bill_type
  ,TESTCENTERNOTES as test_center_notes
  ,FREQUENCY as frequency
  ,date(FREQUENCY_END_DATE) as frequency_end_date
  ,HAS_REMINDER as has_reminder
  ,date(REMIND_DATE) as remind_date
  ,ORDER_STATE as order_state
  ,CREATION_TIME as creation_date_time
  ,date(CREATION_TIME) as creation_date
  ,CREATED_BY_USER_ID as created_by_user_id
  ,date(DELETION_TIME) as deletion_date
  ,to_timestamp(DELETION_TIME) as deletion_datetime
  ,DELETED_BY_USER_ID as deleted_by_user_id
  ,date(SIGNED_TIME) as signed_date
  ,to_timestamp(SIGNED_TIME) as signed_datetime
  ,SIGNED_BY_USER_ID as signed_by_user_id
  ,LAB_ORDER_TESTS_ID as test_id
  ,WAREHOUSE_ID as warehouse_id
  ,to_timestamp(HDB_LAST_SYNC) as hdb_last_sync
 FROM elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.lab_order
  );

