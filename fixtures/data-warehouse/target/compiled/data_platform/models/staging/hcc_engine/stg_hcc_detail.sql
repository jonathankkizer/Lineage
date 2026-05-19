with details as (
-- these details include eligibility type + other HCC configuration parameters, as well as score component
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		'24' as hcc_model,
		'emr_claims' as source_type,
		flt3.key,
		flt3.value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_ec, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3
	where flt.key in ('details')
	and flt2.key in ('coefficients', 'category')
	
	union all
	
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		'24' as hcc_model,
		'emr' as source_type,
		flt3.key,
		flt3.value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_e, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3
	where flt.key in ('details')
	and flt2.key in ('coefficients', 'category')

	union all

	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		'28' as hcc_model,
		'emr_claims' as source_type,
		flt3.key,
		flt3.value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_ec, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3
	where flt.key in ('details')
	and flt2.key in ('coefficients', 'category')
	
	union all
	
	select 
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		'28' as hcc_model,
		'emr' as source_type,
		flt3.key,
		flt3.value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_e, '')))) flt, 
	table(flatten(input => flt.value)) flt2,
	table(flatten(input => flt2.value)) flt3
	where flt.key in ('details')
	and flt2.key in ('coefficients', 'category')
)
select 
	d.hcc_period_patient_skey,
	d.suvida_id,
	d.period_start_date,
	d.period_end_date,
	d.period_month,
	d.period_type,
	d.hcc_model,
	d.source_type,
	d.key as hcc_category,
	cast(d.value as double) as hcc_value,
from details d
where d.value != ''