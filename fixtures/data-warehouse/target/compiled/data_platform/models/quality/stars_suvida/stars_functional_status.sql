with cte_fs_measure as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.encounter_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.encounter_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('1170F','99483','G0438','G0439')
	and year(fp.encounter_date) = year(current_date())
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.encounter_date desc) = 1
)
select
	*,
	'Care for Older Adults - Functional Status' as quality_measure,
from cte_fs_measure