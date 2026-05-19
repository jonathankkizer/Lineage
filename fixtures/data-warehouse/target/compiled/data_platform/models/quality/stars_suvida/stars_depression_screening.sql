with cte_dp_measure as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('G8432', 'G0444', '3725F', '3351F', '3352F', '3353F', '3354F', 'G8431', 'G8433')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Depression Screening' as quality_measure,
from cte_dp_measure