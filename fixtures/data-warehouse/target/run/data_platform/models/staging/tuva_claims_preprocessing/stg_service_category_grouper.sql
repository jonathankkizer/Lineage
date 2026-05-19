
  create or replace   view dw_dev.dev_jkizer_staging.stg_service_category_grouper
  
  copy grants
  
  
  as (
    select
	claim_id,
	claim_line_number,
	claim_type,
	service_category_1,
	service_category_2,
from suvida_tuva.claims_preprocessing.service_category_grouper
  );

