select
	suvida_id,
	iff(numeric_test_value < 150, 0, 1) as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	flr.collected_date as evidence_date,
	test_value as evidence_desc,
	year(flr.collected_date) as evidence_year,
	'Suvida - Thrombocytopenia' as quality_measure,
from dw_dev.dev_jkizer.fct_lab_result flr
where lower(test_name) like '%platelet count%'
and value_type = 'NM'
qualify row_number() over (partition by flr.suvida_id order by flr.collected_date_time desc) = 1