select
    lab_result_skey,
    ipss.suvida_id,
    ipss.elation_id,
    null as report_id,
    null as lab_order_id,
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
    null as value_note,
    null as note,
    flr.creation_date_time,
    flr.creation_date,
    order_signed_date,
    order_signed_datetime,
    row_number() over (
        partition by ipss.suvida_id, test_name, test_category
        order by collected_date_time desc nulls last
    ) as result_rank
from dw_dev.dev_jkizer.fct_lab_result flr
inner join dw_dev.dev_jkizer.int_patient_summary_sandbox ipss
    on flr.suvida_id = ipss.suvida_id
where
    ipss.suvida_id is not null
    and test_name is not null
qualify result_rank <= 5