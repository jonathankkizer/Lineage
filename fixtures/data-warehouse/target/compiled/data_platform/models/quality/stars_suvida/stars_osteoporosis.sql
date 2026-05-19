with cte_os_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('3095F')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
	
	union all
	
	select
		suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		date_for_test as evidence_date,
		resolution_state || ' - ' || test_name as evidence_desc,
		year(date_for_test) as evidence_year,
	from dw_dev.dev_jkizer.fct_misc_orders
	where suvida_id is not null
	and lower(test_name) like '%dexa%'
	qualify row_number() over (partition by suvida_id order by creation_date_time desc) = 1
)
select
	*,
	'Osteoporosis Screening in Older Women' as quality_measure,
from cte_os_measure
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1