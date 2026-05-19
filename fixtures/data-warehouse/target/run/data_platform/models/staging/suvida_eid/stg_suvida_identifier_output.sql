
  create or replace   view dw_dev.dev_jkizer_staging.stg_suvida_identifier_output
  
  copy grants
  
  
  as (
    select
	suvida_id as suvida_id,
	confidence_score as confidence_score,
	member_id as member_id,
	source as source,
	run_datetime as run_datetime
from source_prod.suvida_eid.src_suvida_identifier_output
  );

