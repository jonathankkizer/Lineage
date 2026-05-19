
  
    

create or replace transient table dw_dev.dev_jkizer.fct_consent
    copy grants
    
    
    as (--
-- Description: Patient consent fact derived from Zentake form responses.
--
-- Two source paths, unioned:
--   1. EXPLICIT  — questions where the patient answers yes/no (e.g., the 3 messaging consent
--                  questions on the Electronic & Text Communication Consent Form). Joined via
--                  map_consent_concept where key_type = 'question_concept'. is_consented is
--                  derived from fct_form_response.answer_boolean (yes/si/sí → true; no → false),
--                  with map_consent_field_response as a fallback for non-standard answers.
--   2. IMPLICIT  — forms where submission alone is the consent (Treatment, Vaccine, PT, Procedure,
--                  Telemed, etc.). Joined via map_consent_concept where key_type = 'form_family'
--                  and default_response = 'implicit_yes'. is_consented = true, is_implicit = true.
--
-- Grain: One row per (suvida_id, response_id, consent_category, completed_at_datetime).
--

with explicit_responses as (
    select
        ffr.suvida_id,
        ffr.customer_elation_id,
        ffr.response_id,
        ffr.form_name,
        ffr.form_version,
        ffr.language,
        ffr.regulatory_state,
        ffr.completed_at_datetime,
        ffr.question_concept,
        ffr.answer_text,
        ffr.answer_boolean,
        mcc.consent_category,
        mcc.default_response
    from dw_dev.dev_jkizer.fct_form_response ffr
    inner join dw_dev.dev_jkizer_source.map_consent_concept mcc
        on  mcc.key_type           = 'question_concept'
        and mcc.key_value          = ffr.question_concept
        -- form_family_scope optionally disambiguates question_concepts that recur across
        -- different form families (e.g., "I hereby" appears on both Documentation Assistance
        -- and Social Care forms with different consent semantics).
        and (mcc.form_family_scope is null or mcc.form_family_scope = ffr.form_family)
    where ffr.suvida_id is not null
),

resolved_per_question as (
    select
        er.suvida_id,
        er.customer_elation_id,
        er.response_id,
        er.form_name,
        er.form_version,
        er.language,
        er.regulatory_state,
        er.completed_at_datetime,
        er.consent_category,
        case
            when er.default_response = 'implicit_yes' then true
            when er.answer_boolean is not null         then er.answer_boolean
            when mfr.is_consent is not null            then mfr.is_consent = 1
        end as is_consented_q,
        coalesce(er.default_response = 'implicit_yes', false) as is_implicit_q
    from explicit_responses er
    left join dw_dev.dev_jkizer_source.map_consent_field_response mfr
        on  mfr.question_concept = er.question_concept
        and (lower(trim(mfr.answer)) = lower(trim(er.answer_text)) or mfr.answer = '_')
),

explicit_consents as (
    -- boolor_agg within a submission so multiple consent-bearing questions mapping to the
    -- same category collapse to a single (response, category) row.
    -- Drop rows where is_consented_q couldn't be resolved (e.g., patient submitted the form
    -- but didn't answer the affirmation question). These fall through to the implicit path
    -- via the form_family implicit_yes fallback.
    select
        suvida_id,
        any_value(customer_elation_id)   as customer_elation_id,
        response_id,
        any_value(form_name)             as form_name,
        any_value(form_version)          as form_version,
        any_value(language)              as language,
        any_value(regulatory_state)      as regulatory_state,
        any_value(completed_at_datetime) as completed_at_datetime,
        consent_category,
        boolor_agg(is_consented_q) as is_consented,
        boolor_agg(is_implicit_q)  as is_implicit,
        2                          as path_priority    -- middle precedence
    from resolved_per_question
    where is_consented_q is not null
    group by suvida_id, response_id, consent_category
),

third_party_per_row_override as (
    -- Tier 3c.1: when the patient explicitly answers "No" for every listed third party on
    -- the per-row "Authorized to Involvement" question, override is_consented to false
    -- regardless of the count question. The per-row signal is more specific than the
    -- count-question or implicit-submission signals. Sourced from fct_form_response_row
    -- because fct_form_response collapses multi-row answers via listagg, losing the
    -- per-row signal.
    select
        frr.suvida_id,
        any_value(frr.customer_elation_id) as customer_elation_id,
        frr.response_id,
        any_value(frr.form_name)           as form_name,
        any_value(frr.form_version)        as form_version,
        any_value(frr.language)            as language,
        any_value(frr.regulatory_state)    as regulatory_state,
        max(frr.completed_at_datetime)     as completed_at_datetime,
        'Third Party Involvement'          as consent_category,
        false                              as is_consented,
        false                              as is_implicit,
        1                                  as path_priority   -- highest precedence
    from dw_dev.dev_jkizer.fct_form_response_row frr
    where frr.form_family = 'consent_third_party'
      and lower(frr.question_concept) = 'authorized to involvement'
      and frr.suvida_id is not null
    group by frr.suvida_id, frr.response_id
    having boolor_agg(equal_null(frr.answer_boolean, true))  = false
       and boolor_agg(equal_null(frr.answer_boolean, false)) = true
),

implicit_submissions as (
    -- One row per Zentake submission with form_family attached.
    -- form_name/form_version/language/regulatory_state are constant within a response_id
    -- (one submission = one form), so select distinct preserves the per-submission grain.
    select distinct
        suvida_id,
        customer_elation_id,
        response_id,
        form_name,
        form_family,
        form_version,
        language,
        regulatory_state,
        completed_at_datetime
    from dw_dev.dev_jkizer.fct_form_response
    where suvida_id    is not null
      and form_family  is not null
),

implicit_consents as (
    -- default_response = 'implicit_yes' → submission is consent
    -- default_response = 'implicit_no'  → submission is opt-out (e.g., the Patient
    --                                     Acknowledgement and Consent Opt Out form)
    select
        s.suvida_id,
        s.customer_elation_id,
        s.response_id,
        s.form_name,
        s.form_version,
        s.language,
        s.regulatory_state,
        s.completed_at_datetime,
        mcc.consent_category,
        (mcc.default_response = 'implicit_yes') as is_consented,
        true                                    as is_implicit,
        3                                       as path_priority   -- lowest precedence
    from implicit_submissions s
    inner join dw_dev.dev_jkizer_source.map_consent_concept mcc
        on  mcc.key_type          = 'form_family'
        and mcc.key_value         = s.form_family
        and mcc.default_response in ('implicit_yes', 'implicit_no')
),

all_consents as (
    select * from third_party_per_row_override
    union all
    select * from explicit_consents
    union all
    select * from implicit_consents
)

-- Precedence when multiple paths fire for the same (response, category):
--   1) third_party_per_row_override — most specific signal (per-row Y/N on Third Party form)
--   2) explicit_consents            — yes/no on a specific consent question (e.g., SMS)
--   3) implicit_consents            — form-family default (submission alone = consent)
select
    md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(response_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(consent_category as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(completed_at_datetime as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as consent_skey,
    suvida_id,
    customer_elation_id   as elation_id,
    'Zentake'             as source,
    response_id           as source_key,
    consent_category      as category,
    is_consented,
    is_implicit,
    form_name,
    form_version,
    language,
    regulatory_state,
    completed_at_datetime
from all_consents
qualify row_number() over (
    partition by suvida_id, response_id, consent_category, completed_at_datetime
    order by path_priority
) = 1
    )
;


  