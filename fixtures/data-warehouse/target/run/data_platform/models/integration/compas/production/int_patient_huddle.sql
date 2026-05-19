
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_huddle
    copy grants
    
    
    as (select * from dw_dev.dev_jkizer.patient_huddle_new
    )
;


  