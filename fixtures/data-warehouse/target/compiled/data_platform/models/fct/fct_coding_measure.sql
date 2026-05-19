select
    md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.hcc_category as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.report_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.measure_status as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as coding_measure_diagnosis_skey,
	md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.hcc_category as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.report_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.measure_status as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as coding_measure_skey,
	md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icm.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as attestation_opportunity_skey,
	siw.suvida_id,
	icm.member_id,
	measure_year,
	hcc_category,
	hcc_description,
	hcc_version,
	icd_10_code,
	is_acute_icd,
	iff(icd_10_code is null, false, true) as is_icd_available,
	measure_status,
	measure_detail,
	report_date,
    measure_source,
	src_file_name,
	coding_gap_member_measure_dx_idx as variant_id,
	dense_rank() over (partition by measure_source, measure_year order by report_date desc) as measure_source_year_index, -- 1 = most recent report
from dw_dev.dev_jkizer.intmdt_coding_measure icm
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on icm.member_id = siw.member_id
	and icm.measure_source = siw.source
where measure_status is not null