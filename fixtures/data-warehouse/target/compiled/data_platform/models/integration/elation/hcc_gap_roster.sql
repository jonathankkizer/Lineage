

with 

existing_gaps as (
    select
        caregap_id,
        definition_id,
        patient_id,
        practice_id,
        created_date,
        closed_date,
        status,
        closed_by,
        as_integer(to_variant(details)) as variant_id
    from dw_dev.dev_jkizer_staging.stg_elation_health_care_gap gaps
    left join dw_dev.dev_jkizer_staging.stg_elation_health_care_gap_definition defs
        on trim(lower(gaps.definition_id)) = trim(lower(defs.id))
    where
        defs.class = 'HCC' and
        gaps.deleted_date is null
)

select
    gaps.elation_id,
    defs.id as definition_id,
    exgaps.caregap_id,
    exgaps.practice_id,
    exgaps.created_date,
    exgaps.status,
    exgaps.closed_date,
    exgaps.closed_by,
    exgaps.variant_id,
    pt.provider_npi
from dw_dev.dev_jkizer.patient_hcc_coding_gap gaps
left join dw_dev.dev_jkizer.dim_patient pt
    on gaps.elation_id = pt.elation_id
left join dw_dev.dev_jkizer_staging.stg_elation_health_care_gap_definition defs
    on floor(gaps.measure_year) = year(defs.start_date) and
       trim(lower(gaps.icd_10_code)) = trim(lower(defs.icd_10_code))
left join existing_gaps exgaps
    on gaps.elation_id = exgaps.patient_id and
       defs.id = exgaps.definition_id
where
    gaps.icd_10_code is not null and
    trim(lower(measure_status)) <> 'closed' and    
    year(defs.start_date) = year(getdate()) and
    defs.class = 'HCC' and
    gaps.is_emr_claims_hcc_diagnosis_complete = 0