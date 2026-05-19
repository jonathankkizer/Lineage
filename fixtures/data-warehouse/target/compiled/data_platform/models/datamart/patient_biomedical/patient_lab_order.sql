select 
	lab_order_skey,
	suvida_id,
	elation_id,
	report_id,
	lab_order_id,
	order_state,
	lab_vendor,
	lab_site,
	date_for_test,
	creation_date_time,
	creation_date,
	created_by_user_id,
	signed_date,
	deletion_date,
	lab_order_tests_id,
	order_test_name
from dw_dev.dev_jkizer.fct_lab_order