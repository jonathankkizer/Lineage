select 
    suvida_id,
    elation_id,
    order_id,
    order_type,
    resolution_state,
    clinical_reason, 
    test_name,
    test_score, 
    test_company_name, 
    creation_date_time,
    signed_by,
    case when lower(test_name) like '%echo%' then 1 else 0 end as is_echo_order,
    case when lower(test_name) like '%x-ray%' then 1 else 0 end as is_xray_order,
    case when lower(test_name) like '%mammogram%' then 1 else 0 end as is_mammogram_order,
from  dw_dev.dev_jkizer.fct_misc_orders 
where suvida_id is not null