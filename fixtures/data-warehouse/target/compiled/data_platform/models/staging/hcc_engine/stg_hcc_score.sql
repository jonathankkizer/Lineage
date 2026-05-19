with scores as (
	select 
		otpt.hcc_period_patient_skey,
		'24' as hcc_model,
		'emr_claims' as source_type,
		flt.key,
		cast(flt.value as double) as value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_ec, '')))) flt
	where key in ('risk_score', 'risk_score_adj')

	union all

	select
		otpt.hcc_period_patient_skey,
		'24' as hcc_model,
		'emr_claims_retro' as source_type,
		flt.key,
		cast(flt.value as double) as value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_ecr, '')))) flt
	where key in ('risk_score', 'risk_score_adj')

	union all

	select
		otpt.hcc_period_patient_skey,
		'24' as hcc_model,
		'emr' as source_type,
		flt.key,
		cast(flt.value as double) as value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v24_output_e, '')))) flt
	where key in ('risk_score', 'risk_score_adj')

	union all

	select
		otpt.hcc_period_patient_skey,
		'28' as hcc_model,
		'emr_claims' as source_type,
		flt.key,
		cast(flt.value as double) as value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_ec, '')))) flt
	where key in ('risk_score', 'risk_score_adj')

	union all

	select
		otpt.hcc_period_patient_skey,
		'28' as hcc_model,
		'emr_claims_retro' as source_type,
		flt.key,
		cast(flt.value as double) as value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_ecr, '')))) flt
	where key in ('risk_score', 'risk_score_adj')

	union all

	select
		otpt.hcc_period_patient_skey,
		'28' as hcc_model,
		'emr' as source_type,
		flt.key,
		cast(flt.value as double) as value,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt,
	table(flatten(input => try_parse_json(nullif(v28_output_e, '')))) flt
	where key in ('risk_score', 'risk_score_adj')
), flatten_risk_scores as (
	select
		otpt.hcc_period_patient_skey,
		otpt.suvida_id,
		otpt.period_start_date,
		otpt.period_end_date,
		otpt.period_month,
		otpt.period_type,
		otpt.run_datetime,
		/* V24 E */
		max(iff(hcc_model = '24' and source_type = 'emr' and key = 'risk_score', value, null)) as v24_e_risk_score,
		max(iff(hcc_model = '24' and source_type = 'emr' and key = 'risk_score_adj', value, null)) as v24_e_risk_score_adj,
		/* V24 EC */
		max(iff(hcc_model = '24' and source_type = 'emr_claims' and key = 'risk_score', value, null)) as v24_ec_risk_score,
		max(iff(hcc_model = '24' and source_type = 'emr_claims' and key = 'risk_score_adj', value, null)) as v24_ec_risk_score_adj,
		/* V24 ECR */
		max(iff(hcc_model = '24' and source_type = 'emr_claims_retro' and key = 'risk_score', value, null)) as v24_ecr_risk_score,
		max(iff(hcc_model = '24' and source_type = 'emr_claims_retro' and key = 'risk_score_adj', value, null)) as v24_ecr_risk_score_adj,
		/* V28 E */
		max(iff(hcc_model = '28' and source_type = 'emr' and key = 'risk_score', value, null)) as v28_e_risk_score,
		max(iff(hcc_model = '28' and source_type = 'emr' and key = 'risk_score_adj', value, null)) as v28_e_risk_score_adj,
		/* V28 EC */
		max(iff(hcc_model = '28' and source_type = 'emr_claims' and key = 'risk_score', value, null)) as v28_ec_risk_score,
		max(iff(hcc_model = '28' and source_type = 'emr_claims' and key = 'risk_score_adj', value, null)) as v28_ec_risk_score_adj,
		/* V28 ECR */
		max(iff(hcc_model = '28' and source_type = 'emr_claims_retro' and key = 'risk_score', value, null)) as v28_ecr_risk_score,
		max(iff(hcc_model = '28' and source_type = 'emr_claims_retro' and key = 'risk_score_adj', value, null)) as v28_ecr_risk_score_adj,
	from source_prod.hcc_engine.src_hcc_fhir_json_output otpt
	left join scores sc 
		using(hcc_period_patient_skey)
	group by all
)
select
	frs.*,
	/* blended - logic for transition years*/
	case
		when year(period_month) < 2023 then v24_ec_risk_score_adj
		when year(period_month) = 2023 then (0.67 * v24_ec_risk_score_adj) + (0.33 * v28_ec_risk_score_adj)
		when year(period_month) = 2024 then (0.33 * v24_ec_risk_score_adj) + (0.67 * v28_ec_risk_score_adj)
		when year(period_month) > 2024 then v28_ec_risk_score_adj
	end as blended_ec_risk_score_adj,
	case
		when year(period_month) < 2023 then v24_e_risk_score_adj
		when year(period_month) = 2023 then (0.67 * v24_e_risk_score_adj) + (0.33 * v28_e_risk_score_adj)
		when year(period_month) = 2024 then (0.33 * v24_e_risk_score_adj) + (0.67 * v28_e_risk_score_adj)
		when year(period_month) > 2024 then v28_e_risk_score_adj
	end as blended_e_risk_score_adj,
	case
		when year(period_month) < 2023 then v24_ec_risk_score
		when year(period_month) = 2023 then (0.67 * v24_ec_risk_score) + (0.33 * v28_ec_risk_score)
		when year(period_month) = 2024 then (0.33 * v24_ec_risk_score) + (0.67 * v28_ec_risk_score)
		when year(period_month) > 2024 then v28_ec_risk_score
	end as blended_ec_risk_score,
	case
		when year(period_month) < 2023 then v24_e_risk_score
		when year(period_month) = 2023 then (0.67 * v24_e_risk_score) + (0.33 * v28_e_risk_score)
		when year(period_month) = 2024 then (0.33 * v24_e_risk_score) + (0.67 * v28_e_risk_score)
		when year(period_month) > 2024 then v28_e_risk_score
	end as blended_e_risk_score,
	case
		when year(period_month) < 2023 then v24_ecr_risk_score_adj
		when year(period_month) = 2023 then (0.67 * v24_ecr_risk_score_adj) + (0.33 * v28_ecr_risk_score_adj)
		when year(period_month) = 2024 then (0.33 * v24_ecr_risk_score_adj) + (0.67 * v28_ecr_risk_score_adj)
		when year(period_month) > 2024 then v28_ecr_risk_score_adj
	end as blended_ecr_risk_score_adj,
	case
		when year(period_month) < 2023 then v24_ecr_risk_score
		when year(period_month) = 2023 then (0.67 * v24_ecr_risk_score) + (0.33 * v28_ecr_risk_score)
		when year(period_month) = 2024 then (0.33 * v24_ecr_risk_score) + (0.67 * v28_ecr_risk_score)
		when year(period_month) > 2024 then v28_ecr_risk_score
	end as blended_ecr_risk_score,
	iff(period_type = 'monthly' and period_month = max(period_month) over (), true, false) as is_max_monthly_period,
	iff(period_type = 'rolling_12_month' and period_end_date = max(period_end_date) over (), true, false) as is_max_rolling_12_month,
	iff(period_type = 'rolling_24_month' and period_end_date = max(period_end_date) over (), true, false) as is_max_rolling_24_month,
from flatten_risk_scores frs