select
    lab_result_id as result_id,
    lab_report_id as report_id,
    collected_date_time as collected_datetime,
    resulted_datetime,
    test_category,
    test_name,
from dw_dev.dev_jkizer.int_report ser
left join dw_dev.dev_jkizer_staging.stg_elation_lab_result selr
    on ser.report_id = selr.lab_report_id
where
    selr.is_abnormal = TRUE