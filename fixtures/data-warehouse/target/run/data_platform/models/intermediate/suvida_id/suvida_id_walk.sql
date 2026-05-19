
  
    

create or replace transient table dw_dev.dev_jkizer.suvida_id_walk
    copy grants
    
    
    as (select distinct
	suvida_id,
	member_id,
	source,
	run_datetime
from dw_dev.dev_jkizer_staging.stg_suvida_identifier_output_prod
    )
;


  