
  create or replace   view dw_dev.dev_jkizer_staging.stg_ref_hcc_v24_icd10
  
  copy grants
  
  
  as (
    select
	icd10 as icd_10_code,
	icd10_formatted,
	concat('HCC', hcc_v24) as hcc_code,
	'v24' as hcc_version,
	description
from source_prod.misc.ref_hcc_v24_icd10
  );

