
  create or replace   view dw_dev.dev_jkizer_staging.stg_hcc_icd_diagnosis
  
  copy grants
  
  
  as (
    with map_output as (
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		otpt.run_datetime,
		'24' as hcc_model,
		'emr_claims' as source_type,
		flt3.key as hcc_code,
		flt4.value::varchar as icd_10_code,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_ec, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3,
	table(flatten(input => flt3.value)) flt4,
	where flt.key in ('details')
	and flt2.key in ('cc_to_dx')
	
	union all
	
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		otpt.run_datetime,
		'24' as hcc_model,
		'emr' as source_type,
		flt3.key as hcc_code,
		flt4.value::varchar as icd_10_code,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_e, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3,
	table(flatten(input => flt3.value)) flt4,
	where flt.key in ('details')
	and flt2.key in ('cc_to_dx')
	
	union all
	
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		otpt.run_datetime,
		'28' as hcc_model,
		'emr_claims' as source_type,
		flt3.key as hcc_code,
		flt4.value::varchar as icd_10_code,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_ec, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3,
	table(flatten(input => flt3.value)) flt4,
	where flt.key in ('details')
	and flt2.key in ('cc_to_dx')
	
	union all
	
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		otpt.run_datetime,
		'28' as hcc_model,
		'emr' as source_type,
		flt3.key as hcc_code,
		flt4.value::varchar as icd_10_code,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_e, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3,
	table(flatten(input => flt3.value)) flt4,
	where flt.key in ('details')
	and flt2.key in ('cc_to_dx')
	
), non_diab_hccs_24 as (
	select
		hcc_period_patient_skey,
		suvida_id,
		period_start_date,
		period_end_date,
		period_type,
		source_type,
		hcc_model,
		run_datetime,
		icd_10_code,
		hcc_code,
	from map_output
	where hcc_code not in ('HCC18','HCC19')
	and hcc_model = '24'
), diab_cc_24 as (
	select
		hcc_period_patient_skey,
		suvida_id,
		period_start_date,
		period_end_date,
		period_type,
		source_type,
		hcc_model,
		run_datetime,
		icd_10_code,
		hcc_code,
	from map_output
	where hcc_code in ('HCC18')
	and hcc_model = '24'
), diab_non_cc_24 as (
	select
		mo.hcc_period_patient_skey,
		mo.suvida_id,
		mo.period_start_date,
		mo.period_end_date,
		mo.period_type,
		mo.source_type,
		mo.hcc_model,
		mo.run_datetime,
		mo.icd_10_code,
		mo.hcc_code,
	from map_output mo
	left join diab_cc_24  cc
		on mo.hcc_period_patient_skey = cc.hcc_period_patient_skey
	where mo.hcc_code in ('HCC19')
	and mo.hcc_model = '24'
	and cc.hcc_period_patient_skey is null
), hcc_28 as (
	select
		hcc_period_patient_skey,
		suvida_id,
		period_start_date,
		period_end_date,
		period_type,
		source_type,
		hcc_model,
		run_datetime,
		icd_10_code,
		hcc_code,
		case
			when hcc_code in ('HCC35','HCC36','HCC37','HCC38') then 'diabetes'
			when hcc_code in ('HCC221','HCC222','HCC223','HCC224','HCC225','HCC226','HCC227') then 'heart_failure'
			when hcc_code in ('HCC326','HCC327','HCC328','HCC329') then 'ckd'
			when hcc_code in ('HCC17','HCC18','HCC19','HCC20','HCC21','HCC22','HCC23') then 'cancer'
			when hcc_code in ('HCC80','HCC81') then 'crohns'
			when hcc_code in ('HCC93','HCC94') then 'rheumatoid_arthritis'
			when hcc_code in ('HCC107','HCC108') then 'sickle_cell'
			when hcc_code in ('HCC111','HCC112') then 'hemophilia'
			when hcc_code in ('HCC114','HCC115') then 'common_variable_immunodeficiencies'
			when hcc_code in ('HCC125','HCC126','HCC127') then 'dementia'
			when hcc_code in ('HCC135','HCC136','HCC137','HCC138','HCC139') then 'alcohol_drug_use'
			when hcc_code in ('HCC151','HCC152','HCC153','HCC154','HCC155') then 'schizo_bipolar_personality_disorders'
			else null 
		end as trumping_type,
	from map_output
	where hcc_model = '28'
), hcc_28_trumping as (
	select
		hcc_period_patient_skey,
		suvida_id,
		period_start_date,
		period_end_date,
		period_type,
		source_type,
		hcc_model,
		run_datetime,
		icd_10_code,
		hcc_code,
		iff(trumping_type is not null, dense_rank() over (partition by hcc_period_patient_skey, trumping_type order by replace(hcc_code, 'HCC', '')::number asc), null) as trumping_min_flag
	from hcc_28
)
select
	hcc_period_patient_skey,
	suvida_id,
	period_start_date,
	period_end_date,
	period_type,
	source_type,
	hcc_model,
	run_datetime,
	icd_10_code,
	hcc_code,
from non_diab_hccs_24
union all
select
	hcc_period_patient_skey,
	suvida_id,
	period_start_date,
	period_end_date,
	period_type,
	source_type,
	hcc_model,
	run_datetime,
	icd_10_code,
	hcc_code,
from diab_cc_24
union all
select
	hcc_period_patient_skey,
	suvida_id,
	period_start_date,
	period_end_date,
	period_type,
	source_type,
	hcc_model,
	run_datetime,
	icd_10_code,
	hcc_code,
from diab_non_cc_24
union all
select
	hcc_period_patient_skey,
	suvida_id,
	period_start_date,
	period_end_date,
	period_type,
	source_type,
	hcc_model,
	run_datetime,
	icd_10_code,
	hcc_code,
from hcc_28_trumping
where (trumping_min_flag = 1 or trumping_min_flag is null)
  );

