with cte_bc_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp 
	where fp.cpt_code in ('3014F','G9899')
	and year(fp.cpt_date) > (year(current_date())-2)
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
	
	union all
	
	select
		suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		document_date as evidence_date,
		report_title as evidence_desc,
		year(document_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_elation_report
	where (is_mammo_bilateral = 1 or (is_mammo_right = 1 and is_mammo_left = 1)) -- doctag logic to find mammo reports
	and year(document_date) >= (year(current_date())-2)
	qualify row_number() over (partition by suvida_id order by document_date desc) = 1
	
	/* if we need logic for outstanding reports, can add that here with suvida_numerator = 0 */
	union all  
	select
		suvida_id,
		0 as suvida_numerator,
		1 as suvida_denominator,
		1 as pending_numerator,
		creation_date as evidence_date,
		test_name as evidence_desc,
		year(creation_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_misc_orders
	where (lower(test_name) like '%mammography: diagnostic mammogram bilateral (77066)%' or (lower(test_name) like '%mammography: diagnostic mammogram unilateral right (77065)%' and lower(test_name) like '%mammography: diagnostic mammogram unilateral left (77065)%'))
	and resolution_state = 'outstanding'
	and year(creation_date) = year(current_date())
	qualify row_number() over (partition by suvida_id order by creation_date desc) = 1
)
select
	*,
	'Breast Cancer Screening' as quality_measure,
from cte_bc_measure
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1