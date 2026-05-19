
  
    

create or replace transient table dw_dev.dev_jkizer.patient_procedure
    copy grants
    
    
    as (select
	encounter_skey,
	procedure_skey,
	suvida_id,
	cpt_code,
	encounter_datetime,
	cpt_datetime,
	signed_datetime,
	signed_by_provider_name,
	billing_date,
	source,
from dw_dev.dev_jkizer.fct_procedure
    )
;


  