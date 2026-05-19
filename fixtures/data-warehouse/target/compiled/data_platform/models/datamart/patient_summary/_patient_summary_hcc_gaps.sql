

-- Component: Patient HCC gaps and quality gap data
-- Extracted from patient_summary to reduce model complexity

with gap_data as (
    select
        php.suvida_id,
        php.hcc_category,
        php.hcc_description,
        sc.hcc_community_factor,
        php.payer_icd_10_code,
        php.internal_icd_10_code
    from dw_dev.dev_jkizer.patient_hcc_process php
    left join dw_dev.dev_jkizer_staging.stg_elation_hcc_lookup sc
        on php.hcc_category = sc.hcc_code
        and iff(hcc_version = 28, 2024, 2023) = sc.version
    where php.is_measure_closed = false
    and php.hcc_version = 28
    and php.measure_year = year(current_date())
),

aggregate_gap_data as (
    select
        suvida_id,
        sum(hcc_community_factor) as outstanding_v28_community_raf,
        listagg(hcc_category, ' | ') as outstanding_v28_hcc_category,
        listagg(hcc_description, ' | ') as outstanding_v28_hcc_label,
        listagg(concat(payer_icd_10_code, ' | ', internal_icd_10_code), ' | ') as outstanding_v28_icd_10_code
    from gap_data
    group by all
),

quality_gap_data as (
    select suvida_id,
        sum(case when quality_engine_measure_numerator = 0 then 1 else 0 end) as open_quality_gaps,
        count(quality_measure_skey) as number_of_quality_gaps
    from dw_dev.dev_jkizer.patient_quality_measure
    where measure_year = '2026-01-01'
        and is_measure_year_current_report = 1
    group by suvida_id
),

distinct_hcc_codes as (
    select
        suvida_id,
        hcc_code
    from dw_dev.dev_jkizer.fct_mdportals_diagnosis
    where hcc_v24_community_non_dual_weight is not null
    group by suvida_id, hcc_code
),

mdportal_hcc_codes as (
    select
        suvida_id,
        COUNT(hcc_code) as hcc_ct,
        LISTAGG(hcc_code, ' | ') as hcc_opportunities
    from distinct_hcc_codes
    group by suvida_id
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    coalesce(agd.outstanding_v28_community_raf, 0) as outstanding_v28_community_raf,
    agd.outstanding_v28_hcc_category,
    agd.outstanding_v28_hcc_label,
    agd.outstanding_v28_icd_10_code,
    coalesce(qgd.open_quality_gaps, 0) as open_quality_gaps,
    coalesce(qgd.number_of_quality_gaps, 0) as number_of_quality_gaps,
    coalesce(hcc.hcc_ct, 0) as mdportals_suspect_hcc_opportunities_count,
    hcc.hcc_opportunities as mdportals_suspect_hcc_opportunities
from all_patients ap
left join aggregate_gap_data agd on ap.suvida_id = agd.suvida_id
left join quality_gap_data qgd on ap.suvida_id = qgd.suvida_id
left join mdportal_hcc_codes hcc on ap.suvida_id = hcc.suvida_id