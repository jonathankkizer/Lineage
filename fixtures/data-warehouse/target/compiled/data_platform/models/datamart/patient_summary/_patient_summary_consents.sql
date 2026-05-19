

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