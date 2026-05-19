with cte_de_measure as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where (fp.cpt_code in ('2022F', '2024F', '2026F') 
	     and year(fp.cpt_date) >= year(current_date()) - 1)
		or 
		(fp.cpt_code in ('22023F', '2025F', '2033F') 
	     and year(fp.cpt_date) >= year(current_date()) - 2)
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
	
	union all
	
	select
		fr.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		document_date as evidence_date,
		report_title as evidence_desc,
		year(document_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_elation_report fr
	where 
		((is_positive_diabetic_eye_screen = 1)
			and year(document_date) >= year(current_date()) - 1)
		or
		((is_negative_diabetic_eye_screen = 1)
			and year(document_date) >= year(current_date()) - 2)
	qualify row_number() over (partition by suvida_id order by document_date desc) = 1
)
select
	*,
	'Diabetes Care - Eye Exam' as quality_measure,
from cte_de_measure
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1