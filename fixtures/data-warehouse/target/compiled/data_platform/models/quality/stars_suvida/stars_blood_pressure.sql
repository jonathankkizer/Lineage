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