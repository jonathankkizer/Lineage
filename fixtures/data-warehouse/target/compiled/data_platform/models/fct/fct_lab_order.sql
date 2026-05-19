select 
	md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elo.lab_order_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elo.lab_report_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(lot.lab_order_tests_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as lab_order_skey,
	siw.suvida_id,
	elo.elation_id,
	elo.lab_report_id as report_id,
	elo.lab_order_id,
	elo.order_state,
	elo.lab_vendor,
	elo.lab_site,
	elo.date_for_test,
	elo.creation_date_time,
	elo.creation_date,
	elo.created_by_user_id,
	elo.signed_date,
	elo.deletion_date,
	lot.lab_order_tests_id,
	lot.order_test_name
from dw_dev.dev_jkizer_staging.stg_elation_lab_order elo 
left join dw_dev.dev_jkizer_staging.stg_elation_lab_order_tests lot 
	on elo.lab_order_id = lot.lab_order_id
	and lot.lab_order_tests_index = 1
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on elo.elation_id = siw.member_id
	and siw.source = 'Elation' 
where elo.deletion_date is null