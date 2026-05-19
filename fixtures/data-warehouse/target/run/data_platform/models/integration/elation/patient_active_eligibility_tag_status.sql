
  
    

create or replace transient table dw_dev.dev_jkizer.patient_active_eligibility_tag_status
    copy grants
    
    
    as (with current_tagged_patients as (
    select
        patient_id,
        tag_value
    from dw_dev.dev_jkizer_staging.stg_elation_patient_tag
    where
        tag_value = 'Active Eligibility' and
        deletion_datetime is null
),

patient_tag_status as (
    select
        suvida_id,
        elation_id,
        is_active_assignment,
        case
            when lower(trim(pt.elation_status)) = 'deceased' then 1
            else 0
        end as is_deceased,
        case
            when lower(trim(pt.elation_status)) = 'deceased' then 0
            else is_active_assignment
        end as should_have_tag,
        case
            when tag_value is not null then 1
            else 0
        end as has_active_tag
    from dw_dev.dev_jkizer.dim_patient pt
    full outer join current_tagged_patients ctp on pt.elation_id = ctp.patient_id
)

select *
from patient_tag_status
where should_have_tag <> has_active_tag
    )
;


  