
  
    

create or replace transient table dw_dev.dev_jkizer.int_quality_engine_stage_master
    copy grants
    
    
    as (select 
    quality_measure,
    stage,
    gap_status,
    stage_name,
    description
from dw_dev.dev_jkizer_quality.stg_process_engine_stage_master
    )
;


  