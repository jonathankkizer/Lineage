
  
    

create or replace transient table dw_dev.dev_jkizer.patient_vital
    copy grants
    
    
    as (select
	*
from dw_dev.dev_jkizer.fct_vital
where suvida_id is not null
    )
;


  