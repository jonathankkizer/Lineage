select
    md5(cast(coalesce(cast(qpm.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(stage_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(gap_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(evidence_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(latest_rank_overall as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as row_skey,
    qpm.suvida_id,
    qpm.quality_measure,
    qpm.stage,
    qpm.stage_name,
    qpm.gap_status as status,
    qpm.evidence_desc,
    qpm.evidence_date,
    qpm.measure_year,
    qpm.latest_rank_overall,
    qpm.quality_engine_info_array as evidence
from dw_dev.dev_jkizer_quality.quality_process_measures qpm
right join dw_dev.dev_jkizer.int_patient_summary_uat pt
    on qpm.suvida_id = pt.suvida_id
where
    measure_year = 2025 and
    pt.suvida_id is not null