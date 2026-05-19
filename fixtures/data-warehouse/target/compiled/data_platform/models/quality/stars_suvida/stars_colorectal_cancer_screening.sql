with cte_ccs_doc_tags as (
	select
		fr.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		document_date as evidence_date,
		report_title as evidence_desc,
		year(document_date) as evidence_year,
		object_construct(
            'evidence_date', document_date,
            'evidence_string', evidence_desc
				) as evidence_array
	from dw_dev.dev_jkizer.fct_elation_report fr
	where 
		((is_sigmoidoscopy_negative = 1 or is_sigmoidoscopy_positive = 1)
			and year(document_date) >= year(current_date()) - 5)
		or
		((is_ifobt_negative = 1 or is_ifobt_positive = 1)
			and year(document_date) = year(current_date()))
		or
		((is_colonoscopy_negative = 1 or is_colonoscopy_positive = 1)
			and year(document_date) >= year(current_date()) - 10)
		or
		((is_fit_dna_negative or is_fit_dna_positive = 1)
			and year(document_date) >= year(current_date()) - 3)
	qualify row_number() over (partition by suvida_id order by document_date desc) = 1
),
cte_union as (

	select 
		suvida_id,
		suvida_numerator,
		suvida_denominator,
		pending_numerator,
		evidence_date,
		evidence_desc,
		evidence_year,
		evidence_array
	from cte_ccs_doc_tags

	union all  

	select 
		fp.suvida_id,
		1 suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(fp.cpt_code, '|') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
		object_construct(
            'evidence_date', fp.cpt_date,
            'evidence_string', listagg(fp.cpt_code, '|')
				) as evidence_array
	from dw_dev.dev_jkizer.fct_procedure fp
	left join cte_ccs_doc_tags ccd 
	on fp.suvida_id = ccd.suvida_id
	where fp.cpt_code in ('3017F')
	and year(fp.cpt_date) = year(current_date())
	and ccd.suvida_id is null
	group by fp.suvida_id,fp.cpt_date, fp.billing_date
	qualify rank() over (partition by fp.suvida_id order by fp.billing_date desc) = 1
	
	union all
	
	select
		suvida_id,
		0 as suvida_numerator,---these are the tests where lab referral is placed and the result is not yet available. we have to display them as pending orders.
		1 as suvida_denominator,
		1 as pending_numerator,
		creation_date as evidence_date,
		order_test_name as evidence_desc,
		year(creation_date) as evidence_year,

		object_construct(
            'evidence_date', creation_date,
            'evidence_string', order_test_name
				) as evidence_array
	from dw_dev.dev_jkizer.fct_lab_order
	where order_test_name in ('Cologuard','iFOB - In-House (82274)') 
	and order_state in ('outstanding')
	and year(creation_date) = year(current_date())
	qualify row_number() over (partition by suvida_id order by creation_date desc) = 1
)
select
	*,
	'Colorectal Cancer Screening' as quality_measure,
from cte_union
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1