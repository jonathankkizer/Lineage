
  create or replace   view dw_dev.dev_jkizer_staging.stg_zentake_airbyte_responses
  
  copy grants
  
  
  as (
    -- 
-- Staged Zentake form responses from the Airbyte ingestion path.
-- One row per form submission. Patient demographics extracted from the semi-structured patient variant column.
-- Airbyte source began writing data on 3/27/2026.
--

select
    id as response_id,
    form_id,
    form_name,
    patient:external_id::varchar as customer_elation_id,
    patient:first_name::varchar as customer_first_name,
    patient:last_name::varchar as customer_last_name,
    patient:email::varchar as customer_email,
    created_at::timestamp as sent_at_datetime,
    submitted_at::timestamp as completed_at_datetime,
    is_archived as archived
from airbyte_source_prod.zentake.responses
  );

