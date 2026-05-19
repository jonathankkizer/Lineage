

-- Component: Patient SDOH insecurity flags and form due dates
-- Extracted from patient_summary to reduce model complexity

with sdoh_base as (
    select
        suvida_id,
        falls_insecurity,
        housing_insecurity,
        financial_insecurity,
        food_insecurity,
        transportation_insecurity
    from dw_dev.dev_jkizer.patient_sdoh
),

sdoh_pivot as (
    select
        *
    from dw_dev.dev_jkizer.patient_sdoh
        unpivot(active_insecurities for insecurity_type in (
            food_insecurity,
            housing_insecurity,
            financial_insecurity,
            falls_insecurity,
            transportation_insecurity
        ))
),

insecurities_pivoted as (
    select
        suvida_id,
        case insecurity_type
            when 'FOOD_INSECURITY' then 'Food Insecurity'
            when 'HOUSING_INSECURITY' then 'Housing Insecurity'
            when 'FINANCIAL_INSECURITY' then 'Financial Insecurity'
            when 'FALLS_INSECURITY' then 'Falls Insecurity'
            when 'TRANSPORTATION_INSECURITY' then 'Transportation Insecurity'
            else insecurity_type
        end as insecurity_type,
        active_insecurities
    from sdoh_pivot
    where active_insecurities = 'Insecure'
),

sdoh_rollup as (
    select
        suvida_id,
        'Active Insecurities: ' || listagg(insecurity_type, ' | ') as active_insecurities
    from insecurities_pivoted
    group by suvida_id
),

zentake_forms_due as (
    select
        suvida_id,
        -- SDOH form dates (covers AHC v1, v2_part1, v2_part2, and any future variants)
        max(case when form_family = 'sdoh_ahc' then date(completed_at_datetime) end) as sdoh_most_recent_completion_date,
        dateadd(
            year,
            1,
            max(case when form_family = 'sdoh_ahc' then date(completed_at_datetime) end)
        ) as sdoh_form_due_date,
        -- ROI form dates (covers PHI Receive v1 EN/ES and v26)
        max(case when form_family = 'consent_phi_receive' then date(completed_at_datetime) end) as roi_most_recent_completion_date,
        dateadd(
            year,
            1,
            max(case when form_family = 'consent_phi_receive' then date(completed_at_datetime) end)
        ) as roi_form_due_date,
        max(case
            when form_family = 'consent_phi_receive' and lower(answer_text) like 'other%'
            then '*'
        end) as roi_other_specify_indicator
    from dw_dev.dev_jkizer.fct_form_response
    group by suvida_id
),

fap_program as (
    select
        suvida_id,
        max(date(completed_at_datetime)) as fap_completion_date,
        max(case when completed_at_datetime is not null then 1 else 0 end) as is_fap_enrolled,
        dateadd(year, 1, max(date(completed_at_datetime))) as next_fap_form_due
    from dw_dev.dev_jkizer.fct_form_response
    where form_family    = 'fap'
        and suvida_id            is not null
        and completed_at_datetime is not null
    group by suvida_id
)

select
    sb.suvida_id,
    sb.falls_insecurity,
    sb.housing_insecurity,
    sb.financial_insecurity,
    sb.food_insecurity,
    sb.transportation_insecurity,
    sr.active_insecurities,
    zfd.sdoh_most_recent_completion_date,
    zfd.sdoh_form_due_date,

    -- Financial Assistance Program Flags
    fp.fap_completion_date,
    case when fp.is_fap_enrolled = 1 then TRUE else FALSE end as is_fap_enrolled,
    fp.next_fap_form_due,

    iff(current_date() >= zfd.sdoh_form_due_date or zfd.sdoh_most_recent_completion_date is null, 1, 0) as sdoh_form_due_ind,
    zfd.roi_most_recent_completion_date,
    zfd.roi_form_due_date,
    zfd.roi_other_specify_indicator,
    iff(current_date() >= zfd.roi_form_due_date or zfd.roi_most_recent_completion_date is null, 1, 0) as roi_form_due_ind
from sdoh_base sb
left join sdoh_rollup sr on sb.suvida_id = sr.suvida_id
left join zentake_forms_due zfd on sb.suvida_id = zfd.suvida_id
left join fap_program fp on sb.suvida_id = fp.suvida_id