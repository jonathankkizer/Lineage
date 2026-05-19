
  create or replace   view dw_dev.dev_jkizer_staging.stg_sharepoint_svh_quality_gap_mappings
  
  copy grants
  
  
  as (
    select 
	*
from source_prod.sharepoint.src_sharepoint_suvida_quality_gap_mappings
  );

