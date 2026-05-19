
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_misc_order
  
  copy grants
  
  
  as (
    SELECT  
 UQ_MISC_ORDERS as uq_misc_order
 ,TYPE as order_type
 ,ID as order_id
 ,to_varchar(PATIENT_ID) as elation_id
 ,PRACTICE_ID as practice_id
 ,date(DATE_FOR_TEST) as date_for_test
 ,RESOLUTION_STATE as resolution_state
 ,PRESCRIBER_USER_ID as prescriber_user_id
 ,FOLLOW_UP_METHOD as follow_up_method
 ,CLINICAL_REASON as clinical_reason
 ,PATIENT_INSTRUCTIONS as patient_instructions
 ,ICD10_CODE as icd10_code
 ,NOTES as notes
 ,TEST_NAME as test_name 
 ,TEST_SCORE as test_score 
 ,ALLERGIES as allergies 
 ,B_BLOCKER as b_blocker 
 ,STAT as stat 
 ,CONFIDENTIAL as confidential 
 ,TEST_CENTER_NAME as test_center_name 
 ,TEST_COMPANY_NAME as test_company_name 
 ,date(CREATION_TIME) as creation_date
 , creation_time as creation_date_time
 ,CREATED_BY_USER_ID as created_by_user_id
 ,IS_DELETED as is_deleted
 ,date(DELETION_TIME) as deletion_time
 ,DELETION_TIME as deletion_datetime
 ,DELETED_BY_USER_ID as deleted_by_user_id
 ,date(SIGNED_TIME) as signed_date
 ,SIGNED_TIME as signed_datetime
 ,SIGNED_BY_USER_ID as signed_by_user_id
 ,WAREHOUSE_ID as warehouse_id
 ,HDB_LAST_SYNC as hdb_last_sync
FROM elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.misc_orders
  );

