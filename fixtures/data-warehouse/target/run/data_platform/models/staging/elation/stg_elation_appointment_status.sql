
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_appointment_status
  
  copy grants
  
  
  as (
    select
    UQ_APPOINTMENT_STATUS  as uq_appointment_status,
    ID as appointment_status_id,
    APPOINTMENT_ID as appointment_id,
    STATUS as appointment_status,
    NOTE as note,
    NAME as name_code,
    CREATION_TIME as creation_datetime,
    convert_timezone('UTC', convert_timezone('America/Los_Angeles', creation_datetime)) as creation_datetime_utc,
    date(CREATION_TIME) as creation_date,
    CREATED_BY_USER_ID as created_by_user_id,
    date(DELETION_TIME) as appointment_deletion_date,
    DELETION_TIME as deletion_datetime,
    DELETED_BY_USER_ID as deleted_by_user_id,
    --WAREHOUSE_ID,
    HDB_LAST_SYNC as hdb_last_sync_datetime,
    date(HDB_LAST_SYNC) as _last_sync_date,
    row_number() over (partition by APPOINTMENT_ID order by CREATION_TIME desc) as _idx
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.appointment_status
  );

