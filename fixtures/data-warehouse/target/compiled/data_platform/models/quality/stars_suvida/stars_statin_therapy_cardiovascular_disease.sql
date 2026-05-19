with cte_st_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('4013F','G9664')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Statin Therapy for Cardiovascular Disease' as quality_measure,
from cte_st_measure