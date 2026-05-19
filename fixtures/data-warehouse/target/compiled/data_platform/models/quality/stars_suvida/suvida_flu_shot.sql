with cte_flu_shot as (
select
	fi.suvida_id,
	iff((administered_date) >= '2024-07-01', 1, 0) as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fi.administered_date as evidence_date,
	immunization_name as evidence_desc,
	year(fi.administered_date) as evidence_year,
	'Suvida - Flu Vaccine' as quality_measure,

	object_construct(
            'evidence_date', fi.administered_date,
            'evidence_string', fi.immunization_name
				) as evidence_array
from dw_dev.dev_jkizer.fct_immunization fi
where suvida_id is not null
and lower(immunization_name) like '%flu%'

union 

select 
	suvida_id,
	iff((cpt_date) >= '2024-07-01', 1, 0) as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	cpt_date as evidence_date,
	cpt_code as evidence_desc,
	year(cpt_date) as evidence_year,
	'Suvida - Flu Vaccine' as quality_measure,

	object_construct(
            'evidence_date', cpt_date,
            'evidence_string', cpt_code
				) as evidence_array
from dw_dev.dev_jkizer.fct_procedure 
where cpt_code in ('90653','90656','90657','90658','90660','90661','90662','90673','Q2039','G0008','M0201') 
)
select 
	suvida_id,
	suvida_numerator,
	suvida_denominator,
	pending_numerator,
	evidence_date,
	evidence_desc,
	evidence_year,
	quality_measure,
	evidence_array
from cte_flu_shot
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1