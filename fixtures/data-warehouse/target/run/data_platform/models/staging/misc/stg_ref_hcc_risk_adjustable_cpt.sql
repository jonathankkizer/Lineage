
  create or replace   view dw_dev.dev_jkizer_staging.stg_ref_hcc_risk_adjustable_cpt
  
  copy grants
  
  
  as (
    select
	*
from source_prod.misc.src_ref_risk_adjustable_cpt
  );

