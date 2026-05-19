
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_lab_result_uat
    copy grants
    
    
    as (select
    lab_result_skey,
    suvida_id,
    elation_id,
    report_id,
    lab_order_id,
    lab_vendor,
    lab_result_id,
    test_category,
    test_name,
    test_value,
    numeric_test_value,
    loinc,
    collected_date,
    collected_date_time,
    resulted_date,
    resulted_datetime,
    value_type,
    value_note,
    note,
    creation_date_time,
    creation_date,
    order_signed_date,
    order_signed_datetime,
    row_number() over (
        partition by suvida_id, test_name, test_category
        order by collected_date_time desc nulls last
    ) as result_rank
from dw_dev.dev_jkizer.fct_lab_result
where
    suvida_id is not null
    and test_name is not null
qualify result_rank <= 5
    )
;


  