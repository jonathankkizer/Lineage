
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_connected_organization_specialty
  
  copy grants
  
  
  as (
    select 
    organization_id, 
    id as specialty_id, 
    code, 
    grouping,
    classification, 
    specialization, 
    display_name, 
    phones, 
    specialties
from source_prod.leadingreach.connected_organization_specialty
  );

