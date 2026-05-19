
  create or replace   view dw_dev.dev_jkizer_staging.stg_sharepoint_suvida_facility_name
  
  copy grants
  
  
  as (
    select *
from source_prod.sharepoint.src_sharepoint_suvida_facility_codes
  );

