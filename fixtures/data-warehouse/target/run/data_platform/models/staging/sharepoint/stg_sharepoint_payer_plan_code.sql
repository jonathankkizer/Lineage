
  create or replace   view dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_code
  
  copy grants
  
  
  as (
    select
	*,
	regexp_substr(replace(unique_plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
    md5(cast(coalesce(cast(formatted_plan_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unique_plan_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as plan_code_mapping_skey
from source_prod.sharepoint.src_sharepoint_payer_plan_codes
  );

