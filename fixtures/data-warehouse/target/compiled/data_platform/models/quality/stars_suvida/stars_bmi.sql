with bmi_proc_vital as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,

		object_construct(
            'evidence_date', fp.cpt_date,
            'evidence_string', listagg(cpt_code, ' | ')
        		) as evidence_array
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('G0439')
	and year(fp.cpt_date) = year(current_date())
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
	
	union all
	
	select
		fv.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		date(fv.creation_datetime) as evidence_date,
		to_varchar(fv.bmi) as evidence_desc,
		year(fv.creation_datetime) as evidence_year,

		object_construct(
            'evidence_date', date(fv.creation_datetime),
            'evidence_string', to_varchar(fv.bmi)
        		) as evidence_array
	from dw_dev.dev_jkizer.fct_vital fv
	qualify row_number() over (partition by suvida_id order by fv.creation_datetime desc) = 1
) 
select
	*,
	'Obesity Screening - BMI' as quality_measure,
from bmi_proc_vital
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1