
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_caregaps
  
  copy grants
  
  
  as (
    select
    to_timestamp(CREATED_TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZHTZM') as created_timestamp,
    CREATED_BY as created_by,
    DEFINITION_ID as definition_id,
    IS_DELETED as is_deleted,
    to_timestamp(UPDATED_TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZHTZM') as updated_timestamp,
    UPDATED_BY as updated_by,
    ID as caregaps_id,
    QUALITY_PROGRAM as quality_program,
    CLOSED_DATE as closed_date,
    CLOSED_BY as closed_by,
    CLOSED_BY_CODES	as closed_by_codes,
    to_varchar(PATIENT_ID) as patient_id,
    PRACTICE_ID as practice_id,
    DETAIL as detail,
    STATUS as status
    --WAREHOUSE_ID
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.caregaps
  );

