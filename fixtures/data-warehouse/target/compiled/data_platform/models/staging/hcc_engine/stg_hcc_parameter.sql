with params as (
	select 
		otpt.hcc_period_patient_skey,
		'24' as hcc_model,
		'emr_claims' as source_type,
		flt3.key,
		flt3.value
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_ec, '')))) flt, 
	table(flatten(input => try_parse_json(nullif(flt.value, '')))) flt2,
	table(flatten(input => try_parse_json(nullif(flt2.value, '')))) flt3
	where flt2.key in ('demographics')
	union all
	select 
		otpt.hcc_period_patient_skey,
		'24' as hcc_model,
		'emr' as source_type,
		flt3.key,
		flt3.value
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_e, '')))) flt, 
	table(flatten(input => try_parse_json(nullif(flt.value, '')))) flt2,
	table(flatten(input => try_parse_json(nullif(flt2.value, '')))) flt3
	where flt2.key in ('demographics')

	union all

	select 
		otpt.hcc_period_patient_skey,
		'28' as hcc_model,
		'emr_claims' as source_type,
		flt3.key,
		flt3.value
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_ec, '')))) flt, 
	table(flatten(input => try_parse_json(nullif(flt.value, '')))) flt2,
	table(flatten(input => try_parse_json(nullif(flt2.value, '')))) flt3
	where flt2.key in ('demographics')
	union all
	select 
		otpt.hcc_period_patient_skey,
		'28' as hcc_model,
		'emr' as source_type,
		flt3.key,
		flt3.value
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_e, '')))) flt, 
	table(flatten(input => try_parse_json(nullif(flt.value, '')))) flt2,
	table(flatten(input => try_parse_json(nullif(flt2.value, '')))) flt3
	where flt2.key in ('demographics')
), flatten_params as (
	select
		*
	from params 
	pivot (
		max(value) for Key in ('age', 'category', 'crec', 'disabled', 'dual_elgbl_cd', 'esrd', 'fbd', 
		 'graft_months', 'low_income', 'lti', 'new_enrollee', 'non_aged', 
		 'orec', 'orig_disabled', 'pbd', 'sex', 'snp', 'version')
	)
)
select
	fp.hcc_period_patient_skey,
	fp.hcc_model,
	fp.source_type,
	
	-- numeric
	iff(lower(fp."'age'"::varchar) in ('null',''), null, try_to_number(fp."'age'"::varchar)) as age,
	iff(lower(fp."'graft_months'"::varchar) in ('null',''), null, try_to_number(fp."'graft_months'"::varchar)) as graft_months,
	
	-- booleans
	iff(lower(fp."'disabled'"::varchar) in ('null',''), null, try_to_boolean(fp."'disabled'"::varchar)) as disabled,
	iff(lower(fp."'esrd'"::varchar) in ('null',''), null, try_to_boolean(fp."'esrd'"::varchar)) as esrd,
	iff(lower(fp."'fbd'"::varchar) in ('null',''), null, try_to_boolean(fp."'fbd'"::varchar)) as fbd,
	iff(lower(fp."'low_income'"::varchar) in ('null',''), null, try_to_boolean(fp."'low_income'"::varchar)) as low_income,
	iff(lower(fp."'lti'"::varchar) in ('null',''), null, try_to_boolean(fp."'lti'"::varchar)) as lti,
	iff(lower(fp."'new_enrollee'"::varchar) in ('null',''), null, try_to_boolean(fp."'new_enrollee'"::varchar)) as new_enrollee,
	iff(lower(fp."'non_aged'"::varchar) in ('null',''), null, try_to_boolean(fp."'non_aged'"::varchar)) as non_aged,
	iff(lower(fp."'orig_disabled'"::varchar) in ('null',''), null, try_to_boolean(fp."'orig_disabled'"::varchar)) as orig_disabled,
	iff(lower(fp."'pbd'"::varchar) in ('null',''), null, try_to_boolean(fp."'pbd'"::varchar)) as pbd,
	iff(lower(fp."'snp'"::varchar) in ('null',''), null, try_to_boolean(fp."'snp'"::varchar)) as snp,
	
	-- text
	iff(lower(fp."'category'"::varchar) in ('null',''), null, fp."'category'"::varchar) as category,
	iff(lower(fp."'crec'"::varchar) in ('null',''), null, fp."'crec'"::varchar) as crec,
	iff(lower(fp."'dual_elgbl_cd'"::varchar) in ('null',''), null, fp."'dual_elgbl_cd'"::varchar) as dual_elgbl_cd,
	iff(lower(fp."'orec'"::varchar) in ('null',''), null, fp."'orec'"::varchar) as orec,
	iff(lower(fp."'sex'"::varchar) in ('null',''), null, fp."'sex'"::varchar) as sex,
	iff(lower(fp."'version'"::varchar) in ('null',''), null, fp."'version'"::varchar) as version
from flatten_params fp