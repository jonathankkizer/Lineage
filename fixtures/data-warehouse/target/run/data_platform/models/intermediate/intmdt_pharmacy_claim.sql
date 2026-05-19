
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_pharmacy_claim
    copy grants
    
    
    as (select
    *
from dw_dev.dev_jkizer_staging.stg_devoted_pharmacy_claim
    )
;


  