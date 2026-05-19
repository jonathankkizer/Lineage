select
	fp.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fp.encounter_date as evidence_date,
	listagg(cpt_code, ' | ') as evidence_desc,
	year(fp.encounter_date) as evidence_year,
	'Suvida - Diabetic Foot Exam' as quality_measure,
from dw_dev.dev_jkizer.fct_procedure fp
where fp.cpt_code in ('G9226','2028F')
and year(fp.encounter_date) = year(current_date())
group by all
qualify row_number() over (partition by fp.suvida_id order by fp.encounter_date desc) = 1