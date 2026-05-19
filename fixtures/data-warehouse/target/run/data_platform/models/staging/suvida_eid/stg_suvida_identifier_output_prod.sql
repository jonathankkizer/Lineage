
  create or replace   view dw_dev.dev_jkizer_staging.stg_suvida_identifier_output_prod
  
  copy grants
  
  
  as (
    select
	suvida_id,
	member_id,
	source,
	run_datetime,
	case when source = 'SalesForce' then 'prod_run' else null end as sf_match_type
from source_prod.suvida_eid.vw_src_suvida_identifier_output_prod
where _rn = 1
  );

