
  
    

create or replace transient table dw_dev.dev_jkizer.int_pharmacy
    copy grants
    
    
    as (select
    ncpdp_id,
    store_name,
    address_line1,
    address_line2,
    city,
    state,
    zip,
    phone_primary,
    fax,
    email,
from dw_dev.dev_jkizer_staging.stg_elation_pharmacy
where _idx = 1
    )
;


  