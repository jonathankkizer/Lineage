select
	fmo.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fmo.signed_date as evidence_date,
	fmo.test_score as evidence_desc,
	year(fmo.signed_date) as evidence_year,
	'Suvida - Quantaflo' as quality_measure,
from dw_dev.dev_jkizer.fct_misc_orders fmo
where suvida_id is not null
and lower(test_name) like '%quantaflo%'
and lower(RESOLUTION_STATE) != 'cancelled'
qualify row_number() over (partition by suvida_id order by signed_date desc) = 1