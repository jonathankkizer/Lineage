
  create or replace   view dw_dev.dev_jkizer_staging.stg_tbl_prod_marketbuilder_patient_mailing_list
  
  copy grants
  
  
  as (
    select
	*
from source_prod.marketbuilder.tbl_prod_marketbuilder_patient_mailing_list
  );

