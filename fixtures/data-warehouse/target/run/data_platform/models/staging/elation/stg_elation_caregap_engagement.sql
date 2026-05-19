
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_caregap_engagement
  
  copy grants
  
  
  as (
    select
	*
from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.caregaps_engagement
  );

