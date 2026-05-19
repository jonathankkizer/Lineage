
  
    

create or replace transient table dw_dev.dev_jkizer.patient_lab_value
    copy grants
    
    
    as (select 
    lab_order_id,
    report_id,
	elation_id as patient_id,
    suvida_id,
	lab_vendor as vendor_name,
    lab_result_id,
	test_category,
    test_name,
    collected_date,
	collected_date_time,
	resulted_date,
    datediff(hour, order_signed_datetime, resulted_datetime) as order_result_hours_difference,
    test_value, 
    numeric_test_value,
    iff(numeric_test_value is not null, true, false) as is_numerical_value,
    value_type,
    value_note,
    note
from dw_dev.dev_jkizer.fct_lab_result as lr
    )
;


  