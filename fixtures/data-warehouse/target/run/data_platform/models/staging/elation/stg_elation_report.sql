
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_report
  
  copy grants
  
  
  as (
    select
	ID as report_id,
	to_varchar(PATIENT_ID) as patient_id,
	PRACTICE_ID as practice_id,
	to_timestamp(REPORTED_DATE_TIME) as reported_datetime,
	REPORT_TYPE as report_type,
	REQUISITION_NUMBER as requisition_number,
	ORDER_STATUS as order_status,
	ORDERING_PROVIDER_NAME as ordering_provider_name,
	COPIES_TO as copies_to,
	VENDOR_NAME as vendor_name,
	CUSTOM_TITLE as report_title,
	to_date(DOCUMENT_DATE) as document_date,
	CHART_FEED_DATE as chart_feed_date,
	to_timestamp(CREATION_TIME) as creation_datetime,
	to_timestamp(DELETION_TIME) as deletion_datetime,
	to_timestamp(SIGNED_TIME) as signed_datetime,
	SIGNED_BY_USER_ID as signed_by_user_id,
	'Elation' as source
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.report
where DELETION_TIME is null -- don't want deleted data
  );

