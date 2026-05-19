with  __dbt__cte__suvida_creatinine as (
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
),  __dbt__cte__suvida_egfr as (
select
       flr.suvida_id,
	   flr.collected_date as evidence_date,
		test_value as evidence_desc,
		year(flr.collected_date) as evidence_year,
        1 as suvida_numerator,
        1 as suvida_denominator,
        0 as pending_numerator,
        'Suvida - eGFR' as quality_measure ,
        object_construct(
            'evidence_date', flr.collected_date,
            'evidence_string', flr.test_value
        ) as evidence_array
 from dw_dev.dev_jkizer.fct_lab_result flr
 where flr.test_name in ('EGFR','eGFR non Afr Amer','eGFRcr CKD-EPI','eGFR')
 and flr.value_type = 'NM'
 group by all
 qualify row_number() over (partition by flr.suvida_id order by flr.collected_date desc) = 1
),  __dbt__cte__suvida_microalbumin as (
with cte_microalbumin as (	select
		fp.suvida_id,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('82044', '82043')
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
   and lower(test_name) in ('albumin','albumin/globulin ratio','albumin/creatinine ratio, random urine', 'albumin, urine','urine albumin/urine creatinine ratio','urine albumin, random','albumin, 24 hour urine','microalbumin, urine 24 hour','microalbumin')
   and year(flr.collected_date) = year(current_date())
   qualify row_number() over (partition by flr.suvida_id order by flr.collected_date_time desc) = 1
)
select 
  *,
  'Suvida - Microalbumin' as quality_measure
from cte_microalbumin
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1
), cte_kidney_disease_evaluation as(
   select
		sc.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		greatest(sc.evidence_date, se.evidence_date, sm.evidence_date) as evidence_date,
		concat(concat('creatinine:',sc.evidence_desc),'/ ',se.evidence_desc,'/',concat('microalbumin:',sm.evidence_desc)) as evidence_desc,
		year(greatest(sc.evidence_date, se.evidence_date, sm.evidence_date)) as evidence_year,
	from __dbt__cte__suvida_creatinine sc  
	inner join __dbt__cte__suvida_egfr se  
		on sc.suvida_id = se.suvida_id
	inner join __dbt__cte__suvida_microalbumin sm  
		on sc.suvida_id = sm.suvida_id
	where sc.suvida_numerator = 1 and se.suvida_numerator = 1 and sm.suvida_numerator = 1
	group by all 
)
select
	*,
	'Diabetes Care - Kidney Disease Evaluation' as quality_measure,
from cte_kidney_disease_evaluation
where year(evidence_date) = year(current_date())
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1-- has to be done every year