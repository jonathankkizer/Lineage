with cte_creatinine as (
	select
		fp.suvida_id,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('82570')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1 

	union all
	
	select
       flr.suvida_id,
	   flr.collected_date as evidence_date,
	   test_value as evidence_desc,
	   year(flr.collected_date) as evidence_year,
	   1 as suvida_numerator,
       1 as suvida_denominator,
	   0 as pending_numerator
   from dw_dev.dev_jkizer.fct_lab_result  flr
   where flr.suvida_id is not null
   and lower(test_name) in ('creatinine, random urine','creatinine','protein/creatinine ratio','bun/creatinine ratio','creatinine, 24 hour urine','creatinine, urine, random','creatinine, urine')
   and year(flr.collected_date) = year(current_date())
   qualify row_number() over (partition by flr.suvida_id order by flr.collected_date_time desc) = 1
)
 select  
     *,
	 'Suvida - Creatinine' as quality_measure
from cte_creatinine
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1