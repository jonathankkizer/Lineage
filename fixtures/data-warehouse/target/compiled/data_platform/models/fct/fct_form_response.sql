--
-- Description: Long-and-typed Zentake form response fact. Generalizes form-response persistence
--              for consents, HRAs, SDOH screeners, PT screeners, and other Zentake-driven data.
--
-- Grain: One row per (suvida_id, response_id, question_concept). Multi-select answers are
--        collapsed into a single row via array_agg / listagg of distinct concept-mapped answers.
--
-- Durable handle: form_family + question_concept survive Zentake form-version churn.
--                 form_id is the join key to map_zentake_form_family; missing mappings produce
--                 null form_family (caught by the not_null_proportion test on this model).
--

with with_family as (
    -- form_family/form_version/language/regulatory_state are already resolved upstream in
    -- intmdt_zentake_form (which handles the form_id+form_name composite key for collisions).
    -- Inheriting them here avoids duplicating the join logic in two places.
    select
        suvida_id,
        customer_elation_id,
        response_id,
        form_id,
        form_name,
        form_family,
        form_version,
        language,
        regulatory_state,
        user_id,
        user_email,
        question_id,
        question as question_concept,
        answer   as answer_concept,
        sent_at_datetime,
        completed_at_datetime,
        data_source
    from dw_dev.dev_jkizer.intmdt_zentake_form
),

-- Apply security_status before collapsing — secure_status is per-answer, not per-question.
with_security as (
    select
        wf.*,
        case
            when ss.secure_status = 'Insecure' then true
            when ss.secure_status = 'Secure' then false
        end as is_insecure_per_answer
    from with_family wf
    left join dw_dev.dev_jkizer_source.map_zentake_security_status_concept ss
        on wf.form_id = ss.form_id
        and wf.question_id = ss.question_id
        and trim(upper(wf.answer_concept)) = trim(upper(ss.question_answer))
),

collapsed as (
    select
        suvida_id,
        any_value(customer_elation_id)  as customer_elation_id,
        response_id,
        any_value(form_id)              as form_id,
        any_value(form_name)            as form_name,
        any_value(form_family)          as form_family,
        any_value(form_version)         as form_version,
        any_value(language)             as language,
        any_value(regulatory_state)     as regulatory_state,
        any_value(user_id)              as user_id,
        any_value(user_email)           as user_email,
        any_value(question_id)          as question_id,
        question_concept,
        listagg(distinct answer_concept, ' | ') within group (order by answer_concept) as answer_text,
        array_agg(distinct answer_concept) within group (order by answer_concept)      as answer_array,
        boolor_agg(is_insecure_per_answer) as is_insecure,
        any_value(sent_at_datetime)     as sent_at_datetime,
        any_value(completed_at_datetime) as completed_at_datetime,
        any_value(data_source)          as data_source
    from with_security
    group by suvida_id, response_id, question_concept
)

select
    md5(cast(coalesce(cast(response_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(question_concept as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as form_response_skey,
    suvida_id,
    customer_elation_id,
    response_id,
    form_id,
    form_name,
    form_family,
    form_version,
    language,
    regulatory_state,
    user_id,
    user_email,
    question_id,
    question_concept,
    answer_text,
    answer_array,
    -- Typed-conversion attempts apply only when the question has a single answer choice.
    case when array_size(answer_array) = 1 then try_to_number(answer_text) end as answer_numeric,
    -- True for affirmative answers; false for negative. Recognizes plain yes/no plus
    -- consent-form phrasings (give/withdraw consent, Spanish equivalents, Telemed long-form
    -- answers). Single-answer questions only — multi-select returns null.
    case
        when array_size(answer_array) <> 1                                                 then null
        when lower(trim(answer_text)) in ('yes','si','sí','true','1','give consent')       then true
        when lower(trim(answer_text)) in ('no','false','0','withdraw consent')             then false
        when lower(trim(answer_text)) like 'doy mi consentimiento%'                        then true
        when lower(trim(answer_text)) like 'doy consentimiento%'                           then true
        when lower(trim(answer_text)) like 'retiro%consentimiento%'                        then false
        when lower(trim(answer_text)) like 'usted da consentimiento%'                      then true
        when lower(trim(answer_text)) like 'usted declin%'                                 then false
        when lower(trim(answer_text)) like 'you provide%consent%'                          then true
        when lower(trim(answer_text)) like 'you decline%consent%'                          then false
        when lower(trim(answer_text)) like 'i hereby do not grant%'                        then false
        when lower(trim(answer_text)) like 'i hereby do grant%'                            then true
        when lower(trim(answer_text)) like 'por la presente deneg%'                        then false
        when lower(trim(answer_text)) like 'por la presente doy%'                          then true
    end as answer_boolean,
    case when array_size(answer_array) = 1 then try_to_date(answer_text) end as answer_date,
    case
        when is_insecure = true  then 'Insecure'
        when is_insecure = false then 'Secure'
    end as secure_status,
    is_insecure,
    sent_at_datetime,
    completed_at_datetime,
    data_source
from collapsed