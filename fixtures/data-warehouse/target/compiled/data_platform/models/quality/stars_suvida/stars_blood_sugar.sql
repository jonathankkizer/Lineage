with a1c_cpt_lab_data as (
	select 
		fp.suvida_id,
		max(iff(cpt_code in ('3044F','3051F','3052F'), 1, 0)) as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
   	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in 
	(
    	'3044F','3051F','3052F',-- compliant CPT Codes
    	'3046F'-- non-compliant CPT Codes
	)
	and year(fp.cpt_date) = year(current_date())
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date) = 1
	
	union all
	select
		flr.suvida_id,
		iff(numeric_test_value <= 8.9, 1, 0) as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		flr.collected_date as evidence_date,
		test_value as evidence_desc,
		year(flr.collected_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_lab_result flr
	where lower(test_name) like '%a1c%'
	and value_type = 'NM'
	and year(flr.collected_date) = year(current_date())
	qualify row_number() over (partition by flr.suvida_id order by flr.collected_date_time desc) = 1
)
select
	*,
	'Diabetes Care - Blood Sugar Controlled' as quality_measure,
from a1c_cpt_lab_data
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1