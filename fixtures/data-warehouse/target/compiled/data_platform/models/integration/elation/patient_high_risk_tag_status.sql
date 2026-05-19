with current_tagged_patients as (
    select
        patient_id,
        tag_value
    from dw_dev.dev_jkizer_staging.stg_elation_patient_tag
    where
        tag_value in ('Level 1', 'Level 2', 'Level 3', 'Level 4', 'Level 5') and
        deletion_datetime is null
),

patient_tag_status as (
    select
        ps.suvida_id,
        ps.elation_id,
        ps.is_active_assignment,
        case
            when lower(trim(ps.elation_status)) = 'deceased' then 1
            else 0
        end as is_deceased,
        ps.unplanned_admission_risk_level,
        iff(tag_value is not null, 1, 0) as has_risk_level_tag, 
        case
            when tag_value is null and ps.unplanned_admission_risk_level is not null then 0
            when tag_value is not null and ps.unplanned_admission_risk_level is null then 0
            when tag_value = ps.unplanned_admission_risk_level then 1
            else 0
        end as has_matching_risk_level_tag,
        case
            when lower(trim(ps.elation_status)) = 'deceased' then 0
            when ps.is_active_assignment = 0 then 0
            when ps.unplanned_admission_risk_level is not null then 1
            else 0
        end as should_have_tag
    from dw_dev.dev_jkizer.patient_summary ps
    full outer join current_tagged_patients ctp on ps.elation_id = ctp.patient_id
)

select *
from patient_tag_status
where
    (should_have_tag <> has_risk_level_tag) or
    (should_have_tag = 1 and has_matching_risk_level_tag = 0)