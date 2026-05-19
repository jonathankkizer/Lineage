
  create or replace   view dw_dev.dev_jkizer_staging.stg_atc_codes_to_rxnorm_products
  
  copy grants
  
  
  as (
    select
	*
from source_prod.coderx.atc_codes_to_rxnorm_products
  );

