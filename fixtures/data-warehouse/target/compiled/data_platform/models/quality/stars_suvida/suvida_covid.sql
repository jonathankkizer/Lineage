select
	fi.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fi.administered_date as evidence_date,
	immunization_name as evidence_desc,
	year(fi.administered_date) as evidence_year,
	'Suvida - covid' as quality_measure,
	object_construct(
            'evidence_date', fi.administered_date,
            'evidence_string', case 
				when lower(fi.immunization_name) like '%covid%' then 'covid' end 
				) as evidence_array
from dw_dev.dev_jkizer.fct_immunization fi
where suvida_id is not null
and lower(immunization_name) like '%covid%'
qualify row_number() over (partition by suvida_id order by administered_datetime desc) = 1