
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_provider_specialty
  
  copy grants
  
  
  as (
    select 
    provider_id, 
    id as provider_specialty_id, 
    code,
    grouping,
    classification, 
    specialization,
    display_name
from source_prod.leadingreach.provider_specialty
  );

