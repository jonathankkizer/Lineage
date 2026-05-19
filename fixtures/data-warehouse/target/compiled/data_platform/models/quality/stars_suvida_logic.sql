with  __dbt__cte__stars_advance_care_planning as (
with cte_acp_measure as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('1158F', '1157F', '1123F', '1124F')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Care for Older Adults - Advanced care planning' as quality_measure,
from cte_acp_measure
),  __dbt__cte__stars_awv as (
select
	fp.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fp.cpt_date as evidence_date,
	listagg(cpt_code, ' | ') as evidence_desc,
	year(fp.cpt_date) as evidence_year,
	'Annual Wellness Visit' as quality_measure,
from dw_dev.dev_jkizer.fct_procedure fp
where fp.is_awv = 1
and year(fp.cpt_date) = year(current_date())
group by all
qualify row_number() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
),  __dbt__cte__suvida_creatinine as (
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
),  __dbt__cte__stars_kidney_disease_evaluation as (
with cte_kidney_disease_evaluation as(
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
),  __dbt__cte__stars_blood_pressure as (
with bp_procs as (
	select
		fp.suvida_id,
		fp.encounter_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('3074F','3075F','3078F','3079F','3077F', '3080F')
	and year(fp.encounter_date) = year(current_date())
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.encounter_date desc) = 1
), bp_procs_compliance_vital_data as (
	select -- handle logic to look for compliance or non compliance from CPTs
		suvida_id,
		iff(case 
			when(
				evidence_desc like '%3074F%' or evidence_desc like '%3075F%') 
				and (evidence_desc like '%3078F%' or evidence_desc like '%3079F%') 
				then True 
				else False 
			end
		= True, 1, 0) as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		evidence_date,
		evidence_desc,
		year(evidence_date) as evidence_year,
	from bp_procs
	
	union all
	
	select -- 
		suvida_id,
		iff(is_controlled_blood_pressure = true, 1, 0) as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		date(fv.creation_datetime) as evidence_date,
		fv.blood_pressure_text as evidence_desc,
		year(fv.creation_datetime) as evidence_year,
	from dw_dev.dev_jkizer.fct_vital fv
	where fv.is_controlled_blood_pressure is not null
	and year(fv.creation_datetime) = year(current_date())
	qualify row_number() over (partition by suvida_id order by fv.creation_datetime desc) = 1
)
select
	*,
	'Controlling Blood Pressure' as quality_measure,
from bp_procs_compliance_vital_data
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1
),  __dbt__cte__stars_blood_sugar as (
with a1c_cpt_lab_data as (
	select 
		fp.suvida_id,
		max(iff(cpt_code in ('3044F','3051F','3052F'), 1, 0)) as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
   	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in 
	(
    	'3044F','3051F','3052F',-- compliant CPT Codes
    	'3046F'-- non-compliant CPT Codes
	)
	and year(fp.cpt_date) = year(current_date())
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date) = 1
	
	union all
	select
		flr.suvida_id,
		iff(numeric_test_value <= 8.9, 1, 0) as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		flr.collected_date as evidence_date,
		test_value as evidence_desc,
		year(flr.collected_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_lab_result flr
	where lower(test_name) like '%a1c%'
	and value_type = 'NM'
	and year(flr.collected_date) = year(current_date())
	qualify row_number() over (partition by flr.suvida_id order by flr.collected_date_time desc) = 1
)
select
	*,
	'Diabetes Care - Blood Sugar Controlled' as quality_measure,
from a1c_cpt_lab_data
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1
),  __dbt__cte__stars_bmi as (
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
),  __dbt__cte__stars_breast_cancer_screening as (
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
),  __dbt__cte__stars_colorectal_cancer_screening as (
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
),  __dbt__cte__stars_depression_screening as (
with cte_dp_measure as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('G8432', 'G0444', '3725F', '3351F', '3352F', '3353F', '3354F', 'G8431', 'G8433')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Depression Screening' as quality_measure,
from cte_dp_measure
),  __dbt__cte__stars_diabetic_eye_exam as (
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
),  __dbt__cte__stars_followup_after_emergency_visit as (
with cte_fv_measure as (
	select
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('Z09', '99281', '99282', '99283', '99284', '99285')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Depression Screening' as quality_measure,
from cte_fv_measure
),  __dbt__cte__stars_functional_status as (
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
),  __dbt__cte__stars_medication_review as (
with cte_mr_measure as (
    select
        fp.suvida_id,
        1 as suvida_numerator,
        1 as suvida_denominator,
        0 as pending_numerator,
        max(fp.encounter_date) as evidence_date,
        listagg(fp.cpt_code, ' | ')  as evidence_desc,
        year(max(fp.encounter_date)) as evidence_year
    from dw_dev.dev_jkizer.fct_procedure fp
    where fp.cpt_code IN ('1159F', '1160F')
    and year(fp.encounter_date) = year(current_date())
    group by fp.suvida_id
    having count(distinct fp.cpt_code) = 2 -- Ensures both codes exist
    qualify rank() over (partition by fp.suvida_id order by max(fp.encounter_date) desc) = 1
)
select
    *,
    'Care for Older Adults - Medication Review' as quality_measure
from cte_mr_measure
),  __dbt__cte__stars_osteoporosis as (
with cte_os_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('3095F')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
	
	union all
	
	select
		suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		date_for_test as evidence_date,
		resolution_state || ' - ' || test_name as evidence_desc,
		year(date_for_test) as evidence_year,
	from dw_dev.dev_jkizer.fct_misc_orders
	where suvida_id is not null
	and lower(test_name) like '%dexa%'
	qualify row_number() over (partition by suvida_id order by creation_date_time desc) = 1
)
select
	*,
	'Osteoporosis Screening in Older Women' as quality_measure,
from cte_os_measure
qualify row_number() over (partition by suvida_id order by evidence_date desc) = 1
),  __dbt__cte__stars_osteoporosis_screening_after_fracture as (
with cte_os_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('G8401','3095F','G8399')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Osteoporosis Management Women who had Fx' as quality_measure,
from cte_os_measure
),  __dbt__cte__stars_pain_assessment as (
with cte_pa_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.encounter_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.encounter_date) as evidence_year
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('1125F', '1126F')
	and year(fp.encounter_date) = year(current_date())
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.encounter_date desc) = 1
)
select 
	*,
	'Care for Older Adults - Pain Assessment' as quality_measure,
from cte_pa_measure
),  __dbt__cte__stars_statin_therapy_cardiovascular_disease as (
with cte_st_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('4013F','G9664')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'Statin Therapy for Cardiovascular Disease' as quality_measure,
from cte_st_measure
),  __dbt__cte__stars_trc_med_reconciliation_pd as (
with cte_mr_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('1111F', '99483', '99495', '99496', 'G8427')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'TRC - Medication Reconciliation Post-Discharge' as quality_measure,
from cte_mr_measure
),  __dbt__cte__stars_trc_patient_engagement as (
with cte_trc_measure as (
	select 
		fp.suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		fp.cpt_date as evidence_date,
		listagg(cpt_code, ' | ') as evidence_desc,
		year(fp.cpt_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_procedure fp
	where fp.cpt_code in ('1111F', '99483', '99495', '99496')
	group by all
	qualify rank() over (partition by fp.suvida_id order by fp.cpt_date desc) = 1
)
select
	*,
	'TRC - Patient Engagement after Inpatient Discharge' as quality_measure,
from cte_trc_measure
),  __dbt__cte__suvida_diabetic_foot_exam as (
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
),  __dbt__cte__suvida_flu_shot as (
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
),  __dbt__cte__suvida_pneumococcal as (
select
	fi.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fi.administered_date as evidence_date,
	immunization_name as evidence_desc,
	year(fi.administered_date) as evidence_year,
	'Suvida - Pneumococcal Vaccine' as quality_measure,

	object_construct(
            'evidence_date', fi.administered_date,
            'evidence_string', case	
				when lower(fi.immunization_name) like '%pneumo%' then 'pneumococcal' end
				) as evidence_array
from dw_dev.dev_jkizer.fct_immunization fi
where suvida_id is not null
and (lower(immunization_name) like '%pneumococcal%' or lower(immunization_name) like '%prevnar%')
qualify row_number() over (partition by suvida_id order by administered_datetime desc) = 1
),  __dbt__cte__suvida_quantaflo as (
select
	fmo.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fmo.signed_date as evidence_date,
	fmo.test_score as evidence_desc,
	year(fmo.signed_date) as evidence_year,
	'Suvida - Quantaflo' as quality_measure,
from dw_dev.dev_jkizer.fct_misc_orders fmo
where suvida_id is not null
and lower(test_name) like '%quantaflo%'
and lower(RESOLUTION_STATE) != 'cancelled'
qualify row_number() over (partition by suvida_id order by signed_date desc) = 1
),  __dbt__cte__suvida_tdap as (
select
	fi.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fi.administered_date as evidence_date,
	immunization_name as evidence_desc,
	year(fi.administered_date) as evidence_year,
	'Suvida - TDAP' as quality_measure,
	object_construct(
            'evidence_date', fi.administered_date,
            'evidence_string', case 
				when lower(fi.immunization_name) like '%tdap%' then 'tdap' end 
				) as evidence_array
from dw_dev.dev_jkizer.fct_immunization fi
where suvida_id is not null
and lower(immunization_name) like '%td%'
and year(fi.administered_date) >= year(current_date()) - 10 -- administered within last 10 years
qualify row_number() over (partition by suvida_id order by administered_datetime desc) = 1
),  __dbt__cte__suvida_covid as (
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
),  __dbt__cte__suvida_thrombocytopenia as (
select
	suvida_id,
	iff(numeric_test_value < 150, 0, 1) as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	flr.collected_date as evidence_date,
	test_value as evidence_desc,
	year(flr.collected_date) as evidence_year,
	'Suvida - Thrombocytopenia' as quality_measure,
from dw_dev.dev_jkizer.fct_lab_result flr
where lower(test_name) like '%platelet count%'
and value_type = 'NM'
qualify row_number() over (partition by flr.suvida_id order by flr.collected_date_time desc) = 1
),  __dbt__cte__suvida_echo_screening as (
WITH cte_eligibile AS (
  SELECT 
    suvida_id,
    ICD_10_CODE,
    Diagnosis_date
  FROM dw_dev.dev_jkizer.fct_diagnosis
  WHERE (ICD_10_CODE LIKE '%I10%' 
     OR ICD_10_CODE LIKE '%E11%' 
     OR ICD_10_CODE LIKE '%E78%' 
     OR ICD_10_CODE LIKE '%E66%'
     OR ICD_10_CODE LIKE '%J44%' 
     OR ICD_10_CODE LIKE '%I25%' 
     OR ICD_10_CODE LIKE '%I48%' 
     OR ICD_10_CODE LIKE '%I73%' 
     OR ICD_10_CODE LIKE '%I70%' 
     OR ICD_10_CODE LIKE '%D50%')
    and source_type = 'emr'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY suvida_id ORDER BY Diagnosis_date DESC) = 1
),
cte_echo AS (
  select 
    suvida_id,
		1 as suvida_numerator,
		1 as suvida_denominator,
		0 as pending_numerator,
		document_date as evidence_date,
		report_title as evidence_desc,
		year(document_date) as evidence_year,
	from dw_dev.dev_jkizer.fct_elation_report
	where is_echo = 1 -- doctag logic to find echo reports
	qualify row_number() over (partition by suvida_id order by document_date desc) = 1

  union 

  SELECT 
    suvida_id,
    0 as suvida_numerator,
		1 as suvida_denominator,
		1 as pending_numerator,
    signed_date AS evidence_date,
    CONCAT(test_name, ' ; ', resolution_state, ' ; ', signed_date) AS evidence_desc,
    YEAR(signed_date) AS evidence_year
  FROM dw_dev.dev_jkizer.fct_misc_orders
  WHERE (LOWER(test_name) LIKE '%echocardiogram%' 
     OR LOWER(test_name) LIKE '%echocardiography%')
  and resolution_state = 'outstanding'
  qualify row_number() over (partition by suvida_id order by signed_date desc) = 1
)
SELECT 
  coalesce(ce.suvida_id, co.suvida_id) as suvida_id,
  co.evidence_date,
  co.evidence_year,
  co.evidence_desc,
  coalesce(co.suvida_numerator, 0) as suvida_numerator,
  coalesce(co. suvida_denominator, 1) as suvida_denominator,
  coalesce(co.pending_numerator, 0) as pending_numerator,
  'suvida-echo' AS quality_measure
FROM 
  cte_eligibile ce 
full JOIN ---if the patient doesn't have the diagnosis but has the test done need to pull the records
  cte_echo co 
  ON ce.suvida_id = co.suvida_id
QUALIFY ROW_NUMBER() OVER (PARTITION BY coalesce(ce.suvida_id, co.suvida_id) ORDER BY co.evidence_date DESC) = 1
),  __dbt__cte__suvida_spiro as (
with spiro_exclusions as (
        select 
            suvida_id
        from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis
        where hcc_model = 24
        and source_type = 'emr'
        and period_type = 'rolling_24_month'
        and hcc_code in ('HCC111','HCC112','HCC84','HCC110')
    ),
    cte_eligibility as (
    select 
        suvida_id   
    from dw_dev.dev_jkizer.patient_history 
    where smoker_status_value in ('Smoker, current status unknown','Former smoker','Current every day smoker','Current some day smoker','Heavy tobacco smoker','Light tobacco smoker')
    )
    select 
        ce.suvida_id,
        co.signed_date as evidence_date,
        year(co.signed_date) as evidence_year,
        concat(co.test_name, '; ', co.resolution_state, '; ', co.signed_date) as evidence_desc,
        CASE 
            WHEN lower(co.resolution_state) = 'fulfilled' THEN 1
            ELSE 0 
        END AS suvida_numerator,
        1 as suvida_denominator,
        0 as pending_numerator,
        'suvida-spiro' as quality_measure,
        
        object_construct(
            'evidence_date', co.signed_date,
            'evidence_string', co.test_score
				) as evidence_array
    from cte_eligibility ce
    left join spiro_exclusions se 
    on ce.suvida_id = se.suvida_id
    left join 
    dw_dev.dev_jkizer.fct_misc_orders co 
    on ce.suvida_id = co.suvida_id
    and  lower(co.test_name) like '%spiro%'
    where  se.suvida_id is null
    qualify row_number() over(partition by ce.suvida_id order by ce.suvida_id) = 1
),  __dbt__cte__suvida_zoster as (
select
	fi.suvida_id,
	1 as suvida_numerator,
	1 as suvida_denominator,
	0 as pending_numerator,
	fi.administered_date as evidence_date,
	immunization_name as evidence_desc,
	year(fi.administered_date) as evidence_year,
	'Suvida - Zoster' as quality_measure,

	object_construct(
            'evidence_date', fi.administered_date,
            'evidence_string', case
                when lower(fi.immunization_name) like '%zoster%' then 'zoster' end
				) as evidence_array
from dw_dev.dev_jkizer.fct_immunization fi
where suvida_id is not null
and lower(immunization_name) like '%zoster%'
qualify row_number() over (partition by suvida_id order by administered_datetime desc) = 1
),  __dbt__cte__suvida_pth as (
WITH cte_egfr AS (
    SELECT
        flr.suvida_id,
        flr.collected_date AS egfr_date,
        TRY_CAST(flr.test_value AS FLOAT) AS egfr_value
    FROM dw_dev.dev_jkizer.fct_lab_result flr
    WHERE flr.test_name IN ('EGFR', 'eGFR non Afr Amer', 'eGFRcr CKD-EPI', 'eGFR')
      AND flr.value_type = 'NM'
      AND YEAR(flr.collected_date) = YEAR(CURRENT_DATE())
      AND TRY_CAST(flr.test_value AS FLOAT) <= 59
    QUALIFY ROW_NUMBER() OVER (PARTITION BY flr.suvida_id ORDER BY flr.collected_date DESC) = 1
),
cte_pth AS (
    SELECT
        flr.suvida_id,
        flr.collected_date AS pth_date,
        flr.test_name,
        flr.test_value
    FROM dw_dev.dev_jkizer.fct_lab_result flr
    WHERE LOWER(flr.test_name) LIKE '%pth%'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY flr.suvida_id ORDER BY flr.collected_date DESC) = 1
)
SELECT
    egfr.suvida_id,
    pth.pth_date as evidence_date,
    year(pth.pth_date) as evidence_year,
    concat(pth.test_name, ': ', pth.test_value) as evidence_desc,
    CASE
        WHEN pth.pth_date IS NOT NULL THEN 1 else 0 end as suvida_numerator,
    1 as suvida_denominator,
    0 as pending_numerator,
    'Suvida - PTH' as quality_measure    
FROM cte_egfr egfr
LEFT JOIN cte_pth pth
    ON egfr.suvida_id = pth.suvida_id
), stars_union as (
    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_advance_care_planning
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_awv
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_kidney_disease_evaluation
    union all

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_blood_pressure
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_blood_sugar
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__stars_bmi
    
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_breast_cancer_screening
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array 
    from __dbt__cte__stars_colorectal_cancer_screening
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure ,
        null as evidence_array
    from __dbt__cte__stars_depression_screening
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_diabetic_eye_exam
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_followup_after_emergency_visit
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_functional_status
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array  
    from __dbt__cte__stars_medication_review
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_osteoporosis
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_osteoporosis_screening_after_fracture
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array  
    from __dbt__cte__stars_pain_assessment
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_statin_therapy_cardiovascular_disease
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_trc_med_reconciliation_pd
    union all 

    select  
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__stars_trc_patient_engagement
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_diabetic_foot_exam
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_flu_shot
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_microalbumin
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_creatinine
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_egfr
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_pneumococcal
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_quantaflo
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_tdap
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_covid
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_thrombocytopenia
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_echo_screening
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_spiro
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        evidence_array
    from __dbt__cte__suvida_zoster
    union all

    select 
        suvida_id,
        suvida_numerator,
        suvida_denominator,
		pending_numerator,
        evidence_date,
        to_varchar(evidence_desc) as evidence_desc,
        evidence_year,
        quality_measure,
        null as evidence_array
    from __dbt__cte__suvida_pth
)
select
    md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as stars_suvida_logic_skey,
    suvida_id,
    case 
     when suvida_numerator = 1 then 'closed'
	 when pending_numerator = 1 then 'pending'
	 else 'open' 
    end as suvida_measure_status,
    suvida_numerator,
    suvida_denominator,
	pending_numerator,
    evidence_date,
    evidence_desc,
    evidence_year,
    quality_measure,
    iff(quality_measure like '%Suvida%', 'suvida', 'stars') as measure_type,
    evidence_array
from stars_union