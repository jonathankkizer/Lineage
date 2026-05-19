

with __dbt__cte___patient_summary_consents as (


-- Component: Patient consent flags. Zentake-only — the Elation report path was
-- retired in PR 4 of the Zentake 2026 refactor. Operationally, all consent now
-- flows through Zentake.

with consents_pivoted as (
    -- 9 of the 11 consent flags come 1:1 from dim_patient_consent. Telemedicine
    -- is split below by regulatory_state since the dim doesn't carry state context.
    -- date_signed / form_name / form_version columns pair 1:1 with each flag and emit values
    -- only when the latest event was consented (mirroring the boolean's semantics) — so a
    -- patient who never signed will have flag=0 and metadata=null.
    -- max(case ...) within a single category is grain-safe because dim_patient_consent has
    -- one row per (suvida_id, category) — only one row contributes to each pivot column.
    select
        suvida_id,

        max(case when category = 'Treatment'                  and latest_is_consented then 1 else 0 end)                as consent_to_treatment,
        max(case when category = 'Treatment'                  and latest_is_consented then latest_consent_at end)       as consent_to_treatment_date_signed,
        max(case when category = 'Treatment'                  and latest_is_consented then latest_form_name end)        as consent_to_treatment_form_name,
        max(case when category = 'Treatment'                  and latest_is_consented then latest_form_version end)     as consent_to_treatment_form_version,

        max(case when category = 'Vaccine'                    and latest_is_consented then 1 else 0 end)                as consent_to_vaccine,
        max(case when category = 'Vaccine'                    and latest_is_consented then latest_consent_at end)       as consent_to_vaccine_date_signed,
        max(case when category = 'Vaccine'                    and latest_is_consented then latest_form_name end)        as consent_to_vaccine_form_name,
        max(case when category = 'Vaccine'                    and latest_is_consented then latest_form_version end)     as consent_to_vaccine_form_version,

        max(case when category = 'Physical Therapy'           and latest_is_consented then 1 else 0 end)                as consent_to_physical_therapy,
        max(case when category = 'Physical Therapy'           and latest_is_consented then latest_consent_at end)       as consent_to_physical_therapy_date_signed,
        max(case when category = 'Physical Therapy'           and latest_is_consented then latest_form_name end)        as consent_to_physical_therapy_form_name,
        max(case when category = 'Physical Therapy'           and latest_is_consented then latest_form_version end)     as consent_to_physical_therapy_form_version,

        max(case when category = 'Patient Procedure'          and latest_is_consented then 1 else 0 end)                as consent_to_patient_procedure,
        max(case when category = 'Patient Procedure'          and latest_is_consented then latest_consent_at end)       as consent_to_patient_procedure_date_signed,
        max(case when category = 'Patient Procedure'          and latest_is_consented then latest_form_name end)        as consent_to_patient_procedure_form_name,
        max(case when category = 'Patient Procedure'          and latest_is_consented then latest_form_version end)     as consent_to_patient_procedure_form_version,

        max(case when category = 'Event Participation'        and latest_is_consented then 1 else 0 end)                as consent_to_event_participation,
        max(case when category = 'Event Participation'        and latest_is_consented then latest_consent_at end)       as consent_to_event_participation_date_signed,
        max(case when category = 'Event Participation'        and latest_is_consented then latest_form_name end)        as consent_to_event_participation_form_name,
        max(case when category = 'Event Participation'        and latest_is_consented then latest_form_version end)     as consent_to_event_participation_form_version,

        max(case when category = 'Event Photography'          and latest_is_consented then 1 else 0 end)                as consent_to_event_photography,
        max(case when category = 'Event Photography'          and latest_is_consented then latest_consent_at end)       as consent_to_event_photography_date_signed,
        max(case when category = 'Event Photography'          and latest_is_consented then latest_form_name end)        as consent_to_event_photography_form_name,
        max(case when category = 'Event Photography'          and latest_is_consented then latest_form_version end)     as consent_to_event_photography_form_version,

        max(case when category = 'Electronic Communications'  and latest_is_consented then 1 else 0 end)                as consent_to_electronic_text_communication,
        max(case when category = 'Electronic Communications'  and latest_is_consented then latest_consent_at end)       as consent_to_electronic_text_communication_date_signed,
        max(case when category = 'Electronic Communications'  and latest_is_consented then latest_form_name end)        as consent_to_electronic_text_communication_form_name,
        max(case when category = 'Electronic Communications'  and latest_is_consented then latest_form_version end)     as consent_to_electronic_text_communication_form_version,

        max(case when category = 'Third Party Involvement'    and latest_is_consented then 1 else 0 end)                as consent_to_third_party_involvement,
        max(case when category = 'Third Party Involvement'    and latest_is_consented then latest_consent_at end)       as consent_to_third_party_involvement_date_signed,
        max(case when category = 'Third Party Involvement'    and latest_is_consented then latest_form_name end)        as consent_to_third_party_involvement_form_name,
        max(case when category = 'Third Party Involvement'    and latest_is_consented then latest_form_version end)     as consent_to_third_party_involvement_form_version,

        max(case when category = 'Documentation Assistance'   and latest_is_consented then 1 else 0 end)                as consent_to_documentation_assistance,
        max(case when category = 'Documentation Assistance'   and latest_is_consented then latest_consent_at end)       as consent_to_documentation_assistance_date_signed,
        max(case when category = 'Documentation Assistance'   and latest_is_consented then latest_form_name end)        as consent_to_documentation_assistance_form_name,
        max(case when category = 'Documentation Assistance'   and latest_is_consented then latest_form_version end)     as consent_to_documentation_assistance_form_version,

        max(case when category = 'PHI Release (Receive)'      and latest_is_consented then 1 else 0 end)                as consent_to_receive_phi,
        max(case when category = 'PHI Release (Receive)'      and latest_is_consented then latest_consent_at end)       as consent_to_receive_phi_date_signed,
        max(case when category = 'PHI Release (Receive)'      and latest_is_consented then latest_form_name end)        as consent_to_receive_phi_form_name,
        max(case when category = 'PHI Release (Receive)'      and latest_is_consented then latest_form_version end)     as consent_to_receive_phi_form_version
    from dw_dev.dev_jkizer.dim_patient_consent
    group by suvida_id
),

telemed_latest_submission as (
    -- Latest telemed submission per (suvida_id, regulatory_state). Source for
    -- telemed_by_state below. Kept separate from the pivot because the row_number()
    -- filter can't coexist with the group by in a single select — Snowflake
    -- evaluates qualify after group by.
    select
        suvida_id,
        regulatory_state,
        form_name,
        form_version,
        completed_at_datetime
    from dw_dev.dev_jkizer.fct_form_response
    where form_family = 'consent_telemed'
      and suvida_id   is not null
      and regulatory_state in ('AZ', 'TX')
    qualify row_number() over (
        partition by suvida_id, regulatory_state
        order by completed_at_datetime desc
    ) = 1
),

telemed_by_state as (
    -- The Telemedicine category lumps AZ and TX together in dim_patient_consent
    -- (one row per patient per category). To preserve the existing _az / _tx
    -- column contract, pivot the state-specific flags and form metadata directly.
    select
        suvida_id,
        max(case when regulatory_state = 'AZ' then 1 else 0 end)                  as consent_to_telemedicine_az,
        max(case when regulatory_state = 'AZ' then completed_at_datetime end)     as consent_to_telemedicine_az_date_signed,
        max(case when regulatory_state = 'AZ' then form_name end)                 as consent_to_telemedicine_az_form_name,
        max(case when regulatory_state = 'AZ' then form_version end)              as consent_to_telemedicine_az_form_version,
        max(case when regulatory_state = 'TX' then 1 else 0 end)                  as consent_to_telemedicine_tx,
        max(case when regulatory_state = 'TX' then completed_at_datetime end)     as consent_to_telemedicine_tx_date_signed,
        max(case when regulatory_state = 'TX' then form_name end)                 as consent_to_telemedicine_tx_form_name,
        max(case when regulatory_state = 'TX' then form_version end)              as consent_to_telemedicine_tx_form_version
    from telemed_latest_submission
    group by suvida_id
),

authorized_phi_list as (
    -- Names of third parties the patient authorized to be involved in their care.
    -- Uses fct_form_response_row to pair each name with the same-row "Authorized to
    -- Involvement" Y/N answer. Only names where the paired Y/N is true (or unknown)
    -- are included — explicit "No" rows are excluded.
    --
    -- Reliability caveat: legacy submissions (pre-Jan-2026) derive row_position from
    -- natural storage order. Most pairings are correct; a small number may be misaligned.
    -- Airbyte/backfill submissions (post-Jan-2026) use deterministic JSON array index.
    --
    -- The coalesce(a.is_authorized, true) default means: if a name row has no paired
    -- Y/N (e.g., the patient filled in a Name but skipped the Authorized question),
    -- we include the name. Strict mode (requiring explicit Yes) would risk dropping
    -- legitimate authorizations.
    with name_rows as (
        select
            suvida_id,
            response_id,
            row_position,
            answer_text as name_value
        from dw_dev.dev_jkizer.fct_form_response_row
        where form_family    = 'consent_third_party'
          and lower(question_concept) in ('first name', 'name')
          and suvida_id      is not null
          and answer_text    is not null
    ),
    auth_rows as (
        select
            response_id,
            row_position,
            answer_boolean as is_authorized
        from dw_dev.dev_jkizer.fct_form_response_row
        where form_family   = 'consent_third_party'
          and lower(question_concept) = 'authorized to involvement'
    )
    select
        n.suvida_id,
        listagg(distinct lower(n.name_value), ', ')
            within group (order by lower(n.name_value)) as consent_receive_phi_list
    from name_rows n
    left join auth_rows a
        on  n.response_id  = a.response_id
        and n.row_position = a.row_position
    where coalesce(a.is_authorized, true) = true
    group by n.suvida_id
)

select
    coalesce(cp.suvida_id, ts.suvida_id, phi.suvida_id)                     as suvida_id,

    coalesce(cp.consent_to_treatment, 0)                                    as consent_to_treatment,
    cp.consent_to_treatment_date_signed,
    cp.consent_to_treatment_form_name,
    cp.consent_to_treatment_form_version,

    coalesce(cp.consent_to_vaccine, 0)                                      as consent_to_vaccine,
    cp.consent_to_vaccine_date_signed,
    cp.consent_to_vaccine_form_name,
    cp.consent_to_vaccine_form_version,

    coalesce(cp.consent_to_physical_therapy, 0)                             as consent_to_physical_therapy,
    cp.consent_to_physical_therapy_date_signed,
    cp.consent_to_physical_therapy_form_name,
    cp.consent_to_physical_therapy_form_version,

    coalesce(cp.consent_to_patient_procedure, 0)                            as consent_to_patient_procedure,
    cp.consent_to_patient_procedure_date_signed,
    cp.consent_to_patient_procedure_form_name,
    cp.consent_to_patient_procedure_form_version,

    coalesce(ts.consent_to_telemedicine_az, 0)                              as consent_to_telemedicine_az,
    ts.consent_to_telemedicine_az_date_signed,
    ts.consent_to_telemedicine_az_form_name,
    ts.consent_to_telemedicine_az_form_version,

    coalesce(ts.consent_to_telemedicine_tx, 0)                              as consent_to_telemedicine_tx,
    ts.consent_to_telemedicine_tx_date_signed,
    ts.consent_to_telemedicine_tx_form_name,
    ts.consent_to_telemedicine_tx_form_version,

    coalesce(cp.consent_to_event_participation, 0)                          as consent_to_event_participation,
    cp.consent_to_event_participation_date_signed,
    cp.consent_to_event_participation_form_name,
    cp.consent_to_event_participation_form_version,

    coalesce(cp.consent_to_event_photography, 0)                            as consent_to_event_photography,
    cp.consent_to_event_photography_date_signed,
    cp.consent_to_event_photography_form_name,
    cp.consent_to_event_photography_form_version,

    coalesce(cp.consent_to_electronic_text_communication, 0)                as consent_to_electronic_text_communication,
    cp.consent_to_electronic_text_communication_date_signed,
    cp.consent_to_electronic_text_communication_form_name,
    cp.consent_to_electronic_text_communication_form_version,

    coalesce(cp.consent_to_third_party_involvement, 0)                      as consent_to_third_party_involvement,
    cp.consent_to_third_party_involvement_date_signed,
    cp.consent_to_third_party_involvement_form_name,
    cp.consent_to_third_party_involvement_form_version,

    coalesce(cp.consent_to_documentation_assistance, 0)                     as consent_to_documentation_assistance,
    cp.consent_to_documentation_assistance_date_signed,
    cp.consent_to_documentation_assistance_form_name,
    cp.consent_to_documentation_assistance_form_version,

    coalesce(cp.consent_to_receive_phi, 0)                                  as consent_to_receive_phi,
    cp.consent_to_receive_phi_date_signed,
    cp.consent_to_receive_phi_form_name,
    cp.consent_to_receive_phi_form_version,

    phi.consent_receive_phi_list
from consents_pivoted cp
full outer join telemed_by_state ts on cp.suvida_id = ts.suvida_id
full outer join authorized_phi_list phi on coalesce(cp.suvida_id, ts.suvida_id) = phi.suvida_id
),  __dbt__cte___patient_summary_sdoh as (


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
),  __dbt__cte___patient_summary_notes as (


-- Component: Patient operational notes (insurance changes, chase lists, HRH, etc.)
-- Extracted from patient_summary to reduce model complexity

with non_visit_note_insurance_change as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_insurance_change_note_text
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%pcp change status%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

insurance_verification as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_insurance_verification_note_text
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%insurance eligibility check%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

agent_of_record as (
    select
        suvida_id,
        note_text as recent_agent_of_record_note_text,
        encounter_date as recent_agent_of_record_note_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%agent of record%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

come_back_2_care as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_come_back_care_note_text,
        encounter_date as recent_come_back_care_encounter_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%come back 2 care%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

bp_chase_list as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_bp_chase_note_text,
        encounter_date as recent_bp_chase_note_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%#bpch%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

dm_chase_list as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_dm_chase_note_text,
        encounter_date as recent_dm_chase_note_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%#dmch%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

hrh_dates as (
    select
        suvida_id,
        encounter_date as last_huddle_date,
        followup_note as next_huddle_date_raw,
        regexp_substr(followup_note, '\\d{1,2}[-/]\\d{1,2}[-/]\\d{2,4}') AS next_huddle_date_formatted
    from dw_dev.dev_jkizer.encounter_visit_note
    where full_text_note ilike ('%next hrh date%')
    qualify row_number() over (partition by suvida_id order by encounter_date desc) = 1
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    nvnic.recent_insurance_change_note_text,
    iv.recent_insurance_verification_note_text,
    aor.recent_agent_of_record_note_text,
    aor.recent_agent_of_record_note_date,
    trim(replace(replace(split(aor.recent_agent_of_record_note_text, ': ')[1]::varchar, 'Agent Phone Number', ''), '-', '')) as agent_of_record,
    cb2.recent_come_back_care_note_text,
    cb2.recent_come_back_care_encounter_date,
    bcl.recent_bp_chase_note_text,
    bcl.recent_bp_chase_note_date,
    dcl.recent_dm_chase_note_text,
    dcl.recent_dm_chase_note_date,
    hrh.last_huddle_date,
    hrh.next_huddle_date_raw,
    (coalesce(try_to_date(hrh.next_huddle_date_formatted, 'MM-DD-YYYY'), try_to_date(hrh.next_huddle_date_formatted, 'MM/DD/YY'), try_to_date(hrh.next_huddle_date_formatted, 'MM/DD/YYYY'))) as next_huddle_date_formatted
from all_patients ap
left join non_visit_note_insurance_change nvnic on ap.suvida_id = nvnic.suvida_id
left join insurance_verification iv on ap.suvida_id = iv.suvida_id
left join agent_of_record aor on ap.suvida_id = aor.suvida_id
left join come_back_2_care cb2 on ap.suvida_id = cb2.suvida_id
left join bp_chase_list bcl on ap.suvida_id = bcl.suvida_id
left join dm_chase_list dcl on ap.suvida_id = dcl.suvida_id
left join hrh_dates hrh on ap.suvida_id = hrh.suvida_id
),  __dbt__cte___patient_summary_hcc_gaps as (


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
),  __dbt__cte___patient_summary_engagement as (


-- Component: Patient appointment completion/cancellation/no-show rates (rolling 12 months)
-- Extracted from patient_summary to reduce model complexity

select
    suvida_id,
    -- Completion rates
    div0null(sum(case when is_pcp_appt then appointment_completed_ind end), sum(case when is_pcp_appt then 1 end)) as pcp_appt_completion_rate_rolling_12,
    div0null(sum(case when is_guia_appt then appointment_completed_ind end), sum(case when is_guia_appt then 1 end)) as guia_appt_completion_rate_rolling_12,
    div0null(sum(case when is_mh_appt then appointment_completed_ind end), sum(case when is_mh_appt then 1 end)) as mh_appt_completion_rate_rolling_12,
    div0null(sum(case when is_nutrition_appt then appointment_completed_ind end), sum(case when is_nutrition_appt then 1 end)) as nutrition_appt_completion_rate_rolling_12,
    div0null(sum(case when is_pharmacy_appt then appointment_completed_ind end), sum(case when is_pharmacy_appt then 1 end)) as pharmacy_appt_completion_rate_rolling_12,
    div0null(sum(case when is_pt_appt then appointment_completed_ind end), sum(case when is_pt_appt then 1 end)) as pt_appt_completion_rate_rolling_12,
    -- Cancelled rates
    div0null(sum(case when is_pcp_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_pcp_appt then 1 end)) as pcp_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_guia_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_guia_appt then 1 end)) as guia_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_mh_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_mh_appt then 1 end)) as mh_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_nutrition_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_nutrition_appt then 1 end)) as nutrition_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_pharmacy_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_pharmacy_appt then 1 end)) as pharmacy_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_pt_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_pt_appt then 1 end)) as pt_appt_cancelled_rate_rolling_12,
    -- No-show rates
    div0null(sum(case when is_pcp_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_pcp_appt then 1 end)) as pcp_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_guia_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_guia_appt then 1 end)) as guia_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_mh_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_mh_appt then 1 end)) as mh_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_nutrition_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_nutrition_appt then 1 end)) as nutrition_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_pharmacy_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_pharmacy_appt then 1 end)) as pharmacy_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_pt_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_pt_appt then 1 end)) as pt_appt_no_show_rate_rolling_12
from dw_dev.dev_jkizer.fct_appointment
where appointment_date >= dateadd(month, -12, current_date())
group by suvida_id
),  __dbt__cte___patient_summary_misc as (


-- Component: Miscellaneous patient attributes (transportation, tags, advance planning, MLR, etc.)
-- Extracted from patient_summary to reduce model complexity

with transportation_flag as (
    select
        fd.suvida_id,
        max(transportation_grouping) as transportation_flag,
        max(iff(mtd.diagnosis_grouping in ('Serious Mental Illness','Advanced Illness'), mtd.diagnosis_grouping, null)) as transportation_disability_desc
    from dw_dev.dev_jkizer.fct_diagnosis fd
    inner join dw_dev.dev_jkizer_source.map_transportation_diagnosis mtd
        on replace(fd.icd_10_code, '.', '') = replace(mtd.icd_10_code, '.', '')
    where diagnosis_date >= dateadd(month, -12, current_date())
    and transportation_grouping is not null
    group by 1
),

tag_list as (
    select
        suvida_id,
        listagg(tag_value, ' | ') as active_tag_list,
        max(dg.guia_name) as assigned_guia_name
    from dw_dev.dev_jkizer.fct_patient_tag fpt
    left join dw_dev.dev_jkizer.dim_guia dg
        on fpt.tag_value = dg.tag_guia_role_name
    where is_active_tag = true
    group by 1
),

rolling_12_mlr as (
    select
        pr.suvida_id,
        sum(mmr_revenue) as mmr_revenue,
        sum(pcms.total_paid) as total_claims_cost,
        div0null(sum(pcms.total_paid), sum(mmr_revenue)) as rolling_12_operational_mlr
    from dw_dev.dev_jkizer.patient_revenue pr
    inner join dw_dev.dev_jkizer.patient_claim_monthly_spend pcms
        on pr.suvida_id = pcms.suvida_id
        and pr.mmr_month = pcms.date_month
    where pr.mmr_month <= dateadd(month, -3, date_trunc(month, current_date()))
    and pr.mmr_month >= dateadd(month, -15, date_trunc(month, current_date()))
    group by all
),

advance_planning as (
    select
        suvida_id,
        case when is_advance_care_plan = 1 then CREATION_DATETIME end as advance_care_plan_document_attached_datetime,
        is_advance_care_plan as advance_care_plan_document_attached
    from dw_dev.dev_jkizer.fct_elation_report
    where is_advance_care_plan = 1
    qualify row_number() over(partition by suvida_id order by CREATION_DATETIME desc) = 1
),

pre_visit_coder_review as (
    select
        suvida_id,
        1 as has_pre_visit_coder_review_ytd
    from dw_dev.dev_jkizer.fct_coder_attestation_diagnosis
    where coder_attestation_opportunity_index = 1
        and measure_year = year(current_date())
    group by suvida_id
),

-- ======================================== --
--             Falls Metrics
-- ======================================== --
fall_flags as (
    select distinct mc.encounter_id
    from dw_dev.dev_jkizer_staging.stg_claims_expanded_diagnosis dx
    join dw_dev.dev_jkizer_staging.stg_medical_claim mc
        on dx.claim_id = mc.claim_id
        and dx.data_source = mc.data_source
    where left(dx.icd_10_code, 3) between 'W00' and 'W19'
       or dx.icd_10_code like 'R296%'
       or dx.icd_10_code like 'Z9181%'
),

er_fall_encounters as (
    select
        er.suvida_id,
        count(distinct case when ff.encounter_id is not null then er.encounter_id end) as rolling_12_fall_er_visits
    from dw_dev.dev_jkizer.patient_claim_er er
    left join fall_flags ff on er.encounter_id = ff.encounter_id
    where er.encounter_start_date >= dateadd(month, -12, current_date)
    group by 1
),

ip_fall_encounters as (
    select
        ip.suvida_id,
        count(distinct case when ff.encounter_id is not null then ip.encounter_id end) as rolling_12_fall_ip_visits
    from dw_dev.dev_jkizer.patient_claim_inpatient ip
    left join fall_flags ff on ip.encounter_id = ff.encounter_id
    where ip.encounter_start_date >= dateadd(month, -12, current_date)
    group by 1
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    coalesce(tf.transportation_flag, 'rideshare') as transportation_flag,
    tf.transportation_disability_desc,
    iff(lower(tl.active_tag_list) like '%hrh%', true, false) as is_active_hrh_tag,
    tl.active_tag_list,
    tl.assigned_guia_name,
    mlr.rolling_12_operational_mlr,
    mlr.mmr_revenue as rolling_12_operational_mmr_revenue,
    mlr.total_claims_cost as rolling_12_operational_claims_cost,
    coalesce(apr.advance_care_plan_document_attached, 0) as advance_care_plan_document_attached,
    apr.advance_care_plan_document_attached_datetime,
    coalesce(pvcr.has_pre_visit_coder_review_ytd, 0) as has_pre_visit_coder_review_ytd,
    coalesce(er.rolling_12_fall_er_visits, 0) as rolling_12_fall_er_visits,
    coalesce(ip.rolling_12_fall_ip_visits, 0) as rolling_12_fall_ip_visits
from all_patients ap
left join transportation_flag tf on ap.suvida_id = tf.suvida_id
left join tag_list tl on ap.suvida_id = tl.suvida_id
left join rolling_12_mlr mlr on ap.suvida_id = mlr.suvida_id
left join advance_planning apr on ap.suvida_id = apr.suvida_id
left join pre_visit_coder_review pvcr on ap.suvida_id = pvcr.suvida_id
left join er_fall_encounters er on ap.suvida_id = er.suvida_id
left join ip_fall_encounters ip on ap.suvida_id = ip.suvida_id
),  __dbt__cte___patient_summary_vitals as (


-- Component: Patient vitals (latest height, weight, and BMI)
-- Extracted to provide most recent height/weight/BMI measurements per patient
-- Each vital is ranked independently to handle sporadic data population

with latest_vitals as (
    select
        suvida_id,
        height,
        height_units,
        weight,
        weight_units,
        bmi,
        document_datetime as vital_datetime,
        row_number() over (
            partition by suvida_id
            order by
                case when height is not null then 0 else 1 end,
                document_datetime desc
        ) as height_index,
        row_number() over (
            partition by suvida_id
            order by
                case when weight is not null then 0 else 1 end,
                document_datetime desc
        ) as weight_index,
        row_number() over (
            partition by suvida_id
            order by
                case when bmi is not null then 0 else 1 end,
                document_datetime desc
        ) as bmi_index
    from dw_dev.dev_jkizer.patient_vital
    where height is not null or weight is not null or bmi is not null
),

height_values as (
    select
        suvida_id,
        height as most_recent_height,
        height_units as most_recent_height_units,
        vital_datetime as most_recent_height_date
    from latest_vitals
    where height_index = 1 and height is not null
),

weight_values as (
    select
        suvida_id,
        weight as most_recent_weight,
        weight_units as most_recent_weight_units,
        vital_datetime as most_recent_weight_date
    from latest_vitals
    where weight_index = 1 and weight is not null
),

bmi_values as (
    select
        suvida_id,
        bmi as most_recent_bmi,
        vital_datetime as most_recent_bmi_date
    from latest_vitals
    where bmi_index = 1 and bmi is not null
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    hv.most_recent_height,
    hv.most_recent_height_units,
    hv.most_recent_height_date,
    wv.most_recent_weight,
    wv.most_recent_weight_units,
    wv.most_recent_weight_date,
    bv.most_recent_bmi,
    bv.most_recent_bmi_date
from all_patients ap
left join height_values hv on ap.suvida_id = hv.suvida_id
left join weight_values wv on ap.suvida_id = wv.suvida_id
left join bmi_values bv on ap.suvida_id = bv.suvida_id
) -- Patient Summary: Central patient-level fact table
-- Refactored to use component models for maintainability
-- Output is identical to previous implementation

select
    -- ==========================================
    -- CORE PATIENT IDENTITY (from dim_patient)
    -- ==========================================
    dp.suvida_id,
    dp.elation_id,
    dp.sf_account_id,
    initcap(dp.first_name) as first_name,
    initcap(dp.last_name) as last_name,
    initcap(dp.middle_name) as middle_name,
    initcap(dp.middle_initial) as middle_initial,
    dp.has_data_sharing_consent,
    concat(initcap(dp.first_name), ' ', initcap(dp.last_name)) as full_name,
    dp.preferred_name,
    dp.birth_date,
    dp.deceased_date,
    dp.age_year,
    dp.gender,
    dp.email,
    dp.phone,
    dp.phone_type,
    dp.secondary_phone,
    dp.secondary_phone_type,
    dp.address_line_1,
    dp.address_line_2,
    initcap(dp.city) as city,
    dp.state,
    dp.zip,

    -- ==========================================
    -- PATIENT STATUS & ASSIGNMENT
    -- ==========================================
    coalesce(mf.is_active_patient, 0) as is_active_patient,
    case
        when is_active_patient = 1 then 'active'
        when is_active_patient = 0 and next_pcp_appt_date is not null then 'scheduled'
        else 'inactive_unscheduled'
    end as status_scheduled_bucket,
    coalesce(mf.provider_name, dp.provider_name) as provider_name,
    fpp.provider_name as elation_provider_name,
    coalesce(mf.location_Name, dp.location_name) as location_name,
    pl.location_name as elation_location_name,
    pl.nearest_location_name,
    pl.nearest_location_distance,
    dp.provider_npi,
    dp.location_state,
    dp.market_name,

    -- ==========================================
    -- INSURANCE & ELIGIBILITY
    -- ==========================================
    dp.elation_insurance_name,
    dp.elation_insurance_member_id,
    dp.elation_insurance_plan,
    dp.pref_pharmacy1_ncpdpid,
    dp.pref_pharmacy1_name,
    dp.pref_pharmacy1_address,
    dp.pref_pharmacy1_phone,
    dp.pref_pharmacy2_ncpdpid,
    dp.pref_pharmacy2_name,
    dp.pref_pharmacy2_address,
    dp.pref_pharmacy2_phone,
    dp.is_active_enrollment, -- deprecate
    dp.is_future_enrollment, -- deprecate
    dp.is_active_assignment,
    dp.is_future_assignment,
    dp.payer_parent,
    dp.payer_name,
    dp.payer_contract,
    dp.payer_plan_code,
    dp.payer_plan_name,
    dp.payer_plan_network_type,
    dp.payer_plan_program_type,
    dp.payer_plan_network_program_type,
    dp.payer_member_id,
    dp.payer_medicare_beneficiary_id,
    dp.payer_assigned_provider_name,
    dp.agent_number,
    dp.agent_info,
    iff(mf.dual_status_bool = true, 'Dual', 'Non-Dual') as dual_status,

    -- ==========================================
    -- DEMOGRAPHICS
    -- ==========================================
    dp.marital_status,
    dp.occupation,
    dp.preferred_language,
    dp.spanish_preferred_ind,
    dp.english_preferred_ind,
    dp.race,
    dp.secondary_race,
    dp.ethnicity,
    dp.hispanic_latino_ethnicity_ind,
    dp.elation_patient_url,
    dp.patient_acquisition_type,
    dp.eligibility_start_month,
    dp.eligibility_max_month,
    dp.num_months_since_eligibility_acquisition,
    datediff(day, dp.eligibility_start_month, first_pcp_appt_date) as num_days_eligibility_start_first_suvida_pcp_appt,
    dp.creation_date,
    dp.elation_status,
    dp.has_patient_passport,

    -- ==========================================
    -- RISK SCORES & HCC (from patient_monthly + hcc_gaps component)
    -- ==========================================
    mf.current_year_hcc_engine_raf_type,
    mf.projected_year_hcc_engine_raf_type,
    mf.current_year_hcc_engine_raf_description,
    mf.projected_year_hcc_engine_raf_description,
    mf.original_reason_entitlement_code,
    hcc.open_quality_gaps,
    hcc.number_of_quality_gaps,
    coalesce(mf.emr_risk_score_monthly, 0) as emr_risk_score_ytd,
    coalesce(mf.emr_risk_score_rolling, 0) as emr_risk_score_rolling,
    coalesce(mf.emr_claims_blended_risk_score_adj_monthly, 0) as emr_claims_blended_risk_score_adj_ytd,
    coalesce(mf.emr_claims_blended_risk_score_adj_rolling, 0) as emr_claims_blended_risk_score_adj_rolling,
    coalesce(risk_score_performance_year_projection, 0) as risk_score_performance_year_projection,
    div0null(mf.emr_risk_score_monthly, mf.emr_risk_score_rolling) as emr_hcc_recapture_percent,
    hcc.outstanding_v28_community_raf,
    hcc.outstanding_v28_hcc_category,
    hcc.outstanding_v28_hcc_label,
    hcc.outstanding_v28_icd_10_code,
    coalesce(mf.num_emr_hcc_diagnoses_monthly, 0) as num_hcc_diagnoses_ytd,
    hcc.mdportals_suspect_hcc_opportunities_count,
    hcc.mdportals_suspect_hcc_opportunities,

    -- ==========================================
    -- VISIT COUNTS & DATES (from patient_monthly)
    -- ==========================================
    coalesce(mf.num_pcp_visits_ytd, 0) as num_pcp_visits_ytd,
    coalesce(mf.num_mh_visits_ytd, 0) as num_mh_visits_ytd,
    coalesce(mf.num_pharmacy_visits_ytd, 0) as num_pharmacy_visits_ytd,
    coalesce(mf.num_nutrition_visits_ytd, 0) as num_nutrition_visits_ytd,
    coalesce(mf.num_pt_visits_ytd, 0) as num_pt_visits_ytd,
    coalesce(mf.num_careteam_visits_ytd, 0) as num_careteam_visits_ytd,
    case
        when mf.num_pcp_visits_ytd is null or mf.num_pcp_visits_ytd = 0 then '0 visits'
        when mf.num_pcp_visits_ytd = 1 then '1 visits'
        when mf.num_pcp_visits_ytd between 2 and 4 then '2-4 visits'
        else '4+ visits'
    end as num_pcp_visits_ytd_group,
    coalesce(mf.is_pcp_visit_complete_ytd, 0) as is_pcp_visit_complete_ytd,
    mf.is_pcp_visit_complete_scheduled_ytd,
    mf.is_awv_complete_ytd,
    mf.num_upcoming_pcp_visits,
    mf.num_upcoming_mh_visits,
    mf.num_upcoming_nutrition_visits,
    mf.num_upcoming_pharmacy_visits,
    mf.num_upcoming_careteam_visits,
    mf.num_upcoming_pt_visits,
    mf.num_upcoming_ma_visits,
    mf.first_pcp_appt_date,
    mf.last_pcp_appt_date,
    iff(datediff(day, mf.last_pcp_appt_date, current_date())<=30, true, false) as has_seen_pcp_last_30d,
    iff(datediff(day, mf.last_pcp_appt_date, current_date())<=60, true, false) as has_seen_pcp_last_60d,
    iff(datediff(day, mf.last_pcp_appt_date, current_date())<=90, true, false) as has_seen_pcp_last_90d,
    mf.cumulative_pcp_visits,
    mf.first_mh_appt_date,
    mf.last_mh_appt_date,
    iff(datediff(day, mf.last_mh_appt_date, current_date())<=30, true, false) as has_seen_mh_last_30d,
    iff(datediff(day, mf.last_mh_appt_date, current_date())<=60, true, false) as has_seen_mh_last_60d,
    iff(datediff(day, mf.last_mh_appt_date, current_date())<=90, true, false) as has_seen_mh_last_90d,
    mf.first_pharmacy_appt_date,
    mf.last_pharmacy_appt_date,
    iff(datediff(day, mf.last_pharmacy_appt_date, current_date())<=30, true, false) as has_seen_pharmacy_last_30d,
    iff(datediff(day, mf.last_pharmacy_appt_date, current_date())<=60, true, false) as has_seen_pharmacy_last_60d,
    iff(datediff(day, mf.last_pharmacy_appt_date, current_date())<=90, true, false) as has_seen_pharmacy_last_90d,
    mf.first_nutrition_appt_date,
    mf.last_nutrition_appt_date,
    iff(datediff(day, mf.last_nutrition_appt_date, current_date())<=30, true, false) as has_seen_nutrition_last_30d,
    iff(datediff(day, mf.last_nutrition_appt_date, current_date())<=60, true, false) as has_seen_nutrition_last_60d,
    iff(datediff(day, mf.last_nutrition_appt_date, current_date())<=90, true, false) as has_seen_nutrition_last_90d,
    mf.last_awv_date,
    mf.first_pt_appt_date,
    mf.last_pt_appt_date,
    mf.first_adv_dir_date,
    mf.last_adv_dir_date,
    mf.cumulative_adv_dir_visits,
    case
        when datediff(day, last_pcp_appt_date, current_date()) between 0 and 30 then '0_30_days'
        when datediff(day, last_pcp_appt_date, current_date()) between 31 and 60 then '30_60_days'
        when datediff(day, last_pcp_appt_date, current_date()) between 61 and 90 then '60_90_days'
        when datediff(day, last_pcp_appt_date, current_date()) > 90 then '90+_days'
        else 'no_pcp_visit'
    end as last_pcp_appt_timeframe_bucket,
    mf.next_pcp_appt_date,
    mf.next_mh_appt_date,
    mf.next_nutrition_appt_date,
    mf.next_pharmacy_appt_date,
    mf.next_careteam_appt_date,
    mf.next_pt_appt_date,
    mf.next_ma_appt_date,
    mf.next_ma_appt_description,
    mf.patient_visit_appointment_bucket,
    misc.rolling_12_fall_er_visits,
    misc.rolling_12_fall_ip_visits,

    -- ==========================================
    -- OPERATIONAL NOTES (from notes component)
    -- ==========================================
    notes.recent_come_back_care_note_text,
    notes.recent_come_back_care_encounter_date,
    notes.recent_bp_chase_note_text,
    notes.recent_bp_chase_note_date,
    notes.recent_dm_chase_note_text,
    notes.recent_dm_chase_note_date,
    notes.recent_insurance_change_note_text,
    notes.recent_insurance_verification_note_text,
    notes.recent_agent_of_record_note_text,
    notes.recent_agent_of_record_note_date,
    notes.agent_of_record,
    mf.recent_non_visit_note_text,
    mf.recent_non_visit_note_datetime,
    mf.recent_non_visit_guia_note_text,
    mf.recent_non_visit_guia_note_datetime,

    -- ==========================================
    -- SDOH & FORMS (from sdoh component)
    -- ==========================================
    sdoh.sdoh_most_recent_completion_date,
    sdoh.sdoh_form_due_date,
    coalesce(sdoh.sdoh_form_due_ind, 1) as sdoh_form_due_ind,
    sdoh.roi_most_recent_completion_date,
    sdoh.roi_form_due_date,
    sdoh.roi_other_specify_indicator,
    coalesce(sdoh.roi_form_due_ind, 1) as roi_form_due_ind,
    sdoh.falls_insecurity,
    sdoh.housing_insecurity,
    sdoh.financial_insecurity,
    sdoh.food_insecurity,
    sdoh.transportation_insecurity,
    sdoh.active_insecurities,

        -- Financial Assistance Program Flags
    sdoh.fap_completion_date,
    sdoh.is_fap_enrolled,
    sdoh.next_fap_form_due,

    -- ==========================================
    -- CONSENTS (from consents component)
    -- ==========================================
    consents.consent_to_treatment,
    consents.consent_to_treatment_date_signed,
    consents.consent_to_treatment_form_name,
    consents.consent_to_treatment_form_version,
    consents.consent_to_vaccine,
    consents.consent_to_vaccine_date_signed,
    consents.consent_to_vaccine_form_name,
    consents.consent_to_vaccine_form_version,
    consents.consent_to_physical_therapy,
    consents.consent_to_physical_therapy_date_signed,
    consents.consent_to_physical_therapy_form_name,
    consents.consent_to_physical_therapy_form_version,
    consents.consent_to_patient_procedure,
    consents.consent_to_patient_procedure_date_signed,
    consents.consent_to_patient_procedure_form_name,
    consents.consent_to_patient_procedure_form_version,
    consents.consent_to_telemedicine_az,
    consents.consent_to_telemedicine_az_date_signed,
    consents.consent_to_telemedicine_az_form_name,
    consents.consent_to_telemedicine_az_form_version,
    consents.consent_to_telemedicine_tx,
    consents.consent_to_telemedicine_tx_date_signed,
    consents.consent_to_telemedicine_tx_form_name,
    consents.consent_to_telemedicine_tx_form_version,
    consents.consent_to_event_participation,
    consents.consent_to_event_participation_date_signed,
    consents.consent_to_event_participation_form_name,
    consents.consent_to_event_participation_form_version,
    consents.consent_to_event_photography,
    consents.consent_to_event_photography_date_signed,
    consents.consent_to_event_photography_form_name,
    consents.consent_to_event_photography_form_version,
    consents.consent_to_electronic_text_communication,
    consents.consent_to_electronic_text_communication_date_signed,
    consents.consent_to_electronic_text_communication_form_name,
    consents.consent_to_electronic_text_communication_form_version,
    consents.consent_to_third_party_involvement,
    consents.consent_to_third_party_involvement_date_signed,
    consents.consent_to_third_party_involvement_form_name,
    consents.consent_to_third_party_involvement_form_version,
    consents.consent_to_documentation_assistance,
    consents.consent_to_documentation_assistance_date_signed,
    consents.consent_to_documentation_assistance_form_name,
    consents.consent_to_documentation_assistance_form_version,
    consents.consent_to_receive_phi,
    consents.consent_to_receive_phi_date_signed,
    consents.consent_to_receive_phi_form_name,
    consents.consent_to_receive_phi_form_version,
    consents.consent_receive_phi_list,

    -- ==========================================
    -- RISK LEVELS & HIGH RISK FLAGS
    -- ==========================================
    dp.readmission_risk_level,
    dp.ed_utilizer_risk_level,
    dp.unplanned_admission_risk_level,
    dp.dialysis_risk_level,
    dp.mortality_risk_level,
    mf.census_rolling_3_ip_admit,
    mf.census_rolling_6_ip_admit,
    mf.census_rolling_12_ip_admit,
    mf.census_rolling_3_er_event,
    mf.census_rolling_6_er_event,
    mf.census_rolling_12_er_event,
    mf.census_rolling_12_snf_event,
    mf.census_rolling_12_rehab_event,
    mf.census_rolling_12_ip_readmit_30day,
    mf.census_most_recent_ip_admit_date,
    mf.census_most_recent_er_admit_date,

    -- ==========================================
    -- TRANSPORTATION & TAGS (from misc component)
    -- ==========================================
    misc.transportation_flag,
    misc.transportation_disability_desc,
    misc.is_active_hrh_tag,
    misc.active_tag_list,
    misc.assigned_guia_name,

    -- ==========================================
    -- HIGH RISK PATIENT CALCULATIONS
    -- ==========================================
    case
        when
            (
                dp.unplanned_admission_risk_level in ('Level 4', 'Level 5')
                or dp.mortality_risk_level = 'Level 5'
                or dp.readmission_risk_level = 'Level 5'
            )
            and (
                mf.census_rolling_12_ip_admit > 0
                or mf.census_rolling_12_er_event > 1
            )
            or lower(misc.active_tag_list) like '%hrh%'
            or (mf.census_rolling_12_ip_admit > 2 or mf.census_rolling_12_er_event > 2)
        then 1 else 0
    end as high_risk_patient,
    case
        when high_risk_patient = 1 then '1 - HIGH-RISK'
        when mf.emr_claims_blended_risk_score_adj_rolling > 1.5
            or iff(mf.dual_status_bool = true, 'Dual', 'Non-Dual') = 'Dual' then '2 - COMPLEX'
        when mf.cumulative_pcp_visits between 1 and 3 then '3 - LOW TOTAL VISITS'
        else '4 - ALL OTHERS'
    end as come_back_to_care_priority,
    case
        when (((dp.unplanned_admission_risk_level in ('Level 4', 'Level 5') or dp.mortality_risk_level = 'Level 5'  or dp.readmission_risk_level = 'Level 5')
        and (mf.census_rolling_12_ip_admit > 0 or mf.census_rolling_12_er_event > 1))
            or lower(misc.active_tag_list) like '%hrh%'
            or (mf.census_rolling_12_ip_admit > 2 or mf.census_rolling_12_er_event > 2))
        and datediff(day,mf.last_pcp_appt_date,current_date) <= 30
        then 1 else 0
    end as high_risk_patient_visit_completed_last_30days,

    -- ==========================================
    -- HRH HUDDLE DATES (from notes component)
    -- ==========================================
    notes.last_huddle_date,
    notes.next_huddle_date_raw,
    notes.next_huddle_date_formatted,

    -- ==========================================
    -- FINANCIAL (from misc component)
    -- ==========================================
    misc.rolling_12_operational_mlr,
    misc.rolling_12_operational_mmr_revenue,
    misc.rolling_12_operational_claims_cost,

    -- ==========================================
    -- ADVANCE CARE & CODER REVIEW (from misc component)
    -- ==========================================
    misc.advance_care_plan_document_attached,
    misc.advance_care_plan_document_attached_datetime,
    misc.has_pre_visit_coder_review_ytd,

    -- ==========================================
    -- CLINICAL PROGRAMS (from patient_monthly)
    -- ==========================================
    mf.pharmd_eligible,
    mf.pharmd_referred,
    mf.pharmd_visit_enrolled,
    mf.pharmd_tag_enrolled,
    mf.rd_eligible,
    mf.rd_referred,
    mf.rd_visit_enrolled,
    mf.rd_tag_enrolled,
    mf.pt_eligible,
    mf.pt_referred,
    mf.pt_visit_enrolled,
    mf.pt_tag_enrolled,
    mf.mh_eligible,
    mf.mh_referred,
    mf.mh_visit_enrolled,
    mf.mh_tag_enrolled,

    -- ============================================================
    -- APPOINTMENT ENGAGEMENT RATES (from engagement component)
    -- ============================================================
    eng.pcp_appt_completion_rate_rolling_12,
    eng.guia_appt_completion_rate_rolling_12,
    eng.mh_appt_completion_rate_rolling_12,
    eng.nutrition_appt_completion_rate_rolling_12,
    eng.pharmacy_appt_completion_rate_rolling_12,
    eng.pt_appt_completion_rate_rolling_12,
    eng.pcp_appt_cancelled_rate_rolling_12,
    eng.guia_appt_cancelled_rate_rolling_12,
    eng.mh_appt_cancelled_rate_rolling_12,
    eng.nutrition_appt_cancelled_rate_rolling_12,
    eng.pharmacy_appt_cancelled_rate_rolling_12,
    eng.pt_appt_cancelled_rate_rolling_12,
    eng.pcp_appt_no_show_rate_rolling_12,
    eng.guia_appt_no_show_rate_rolling_12,
    eng.mh_appt_no_show_rate_rolling_12,
    eng.nutrition_appt_no_show_rate_rolling_12,
    eng.pharmacy_appt_no_show_rate_rolling_12,
    eng.pt_appt_no_show_rate_rolling_12,

    -- ==========================================
    -- PATIENT VITALS (from vitals component)
    -- ==========================================
    vitals.most_recent_height,
    vitals.most_recent_height_units,
    vitals.most_recent_height_date,
    vitals.most_recent_weight,
    vitals.most_recent_weight_units,
    vitals.most_recent_weight_date,
    vitals.most_recent_bmi,
    vitals.most_recent_bmi_date

from dw_dev.dev_jkizer.dim_patient dp

-- Existing model references
left join dw_dev.dev_jkizer.fct_patient_location pl
    on dp.suvida_id = pl.suvida_id
left join dw_dev.dev_jkizer.fct_patient_provider fpp
    on dp.suvida_id = fpp.suvida_id
left join dw_dev.dev_jkizer.patient_monthly mf
    on dp.suvida_id = mf.suvida_id
    and mf.is_max_period = true

-- Component model joins
left join __dbt__cte___patient_summary_consents consents
    on dp.suvida_id = consents.suvida_id
left join __dbt__cte___patient_summary_sdoh sdoh
    on dp.suvida_id = sdoh.suvida_id
left join __dbt__cte___patient_summary_notes notes
    on dp.suvida_id = notes.suvida_id
left join __dbt__cte___patient_summary_hcc_gaps hcc
    on dp.suvida_id = hcc.suvida_id
left join __dbt__cte___patient_summary_engagement eng
    on dp.suvida_id = eng.suvida_id
left join __dbt__cte___patient_summary_misc misc
    on dp.suvida_id = misc.suvida_id
left join __dbt__cte___patient_summary_vitals vitals
    on dp.suvida_id = vitals.suvida_id