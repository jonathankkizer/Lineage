
  
    

create or replace transient table dw_dev.dev_jkizer.patient_immunization
    copy grants
    
    
    as (select
	*
from dw_dev.dev_jkizer.fct_immunization
    )
;


  