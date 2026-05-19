
  
    

create or replace transient table dw_dev.dev_jkizer.hcc_suspect_combined
    copy grants
    
    
    as (select 
    suvida_id, 
    'morbid_obesity' as hcc_suspect,
    suspect_icd_10_code, 
    bmi as suspect_reading,
    hcc_suspect_info_array
from dw_dev.dev_jkizer.suspect_morbid_obesity
where suspect_icd_10_code is not null

union all 

select 
    suvida_id, 
    'ckd' as hcc_suspect, 
    suspect_icd_10_code, 
    highest_test_value as suspect_reading, 
    last_2_readings as hcc_suspect_info_array 
from dw_dev.dev_jkizer.suspect_ckd
    )
;


  