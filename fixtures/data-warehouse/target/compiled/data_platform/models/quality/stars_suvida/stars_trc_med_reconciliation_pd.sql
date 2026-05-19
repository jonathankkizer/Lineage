with cte_mr_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('1111F', '99483', '99495', '99496', 'G8427')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'TRC - Medication Reconciliation Post-Discharge' as quality_measure,
from cte_mr_measure