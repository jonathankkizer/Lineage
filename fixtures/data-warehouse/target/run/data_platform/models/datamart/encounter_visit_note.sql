
  
    

create or replace transient table dw_dev.dev_jkizer.encounter_visit_note
    copy grants
    
    
    as (select
	*
from dw_dev.dev_jkizer.fct_visit_note fvn
where suvida_id is not null
    )
;


  