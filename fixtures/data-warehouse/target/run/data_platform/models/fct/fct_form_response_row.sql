
  
    

create or replace transient table dw_dev.dev_jkizer.fct_form_response_row
    copy grants
    
    
    as (--
-- Description: Per-row form response fact. Sibling to fct_form_response, but preserves
--              row identity for multi-row forms (e.g., Third Party Involvement, where the
--              patient lists up to 6 third parties each with their own Name/Phone/Relationship/
--              Authorized-to-Involvement fields).
--
-- Grain: One row per (suvida_id, response_id, row_position, question_concept).
--        Multi-select answer choices within a single row are collapsed via array_agg/listagg.
--
-- row_position derivation: dense_rank() over (partition by response_id, question_concept
--                          order by question_position). The Nth occurrence of each
--                          question_concept within a response is row_position N.
--
-- Reliability:
--   - airbyte/backfill submissions: question_position comes from JSON array index, deterministic.
--   - legacy submissions: question_position is best-effort via natural storage order. Pairing
--                         may be slightly off in rare edge cases. See option-A signoff for context.
--

with intmdt as (
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
        question_position,
        question         as question_concept,
        answer           as answer_concept,
        sent_at_datetime,
        completed_at_datetime,
        data_source
    from dw_dev.dev_jkizer.intmdt_zentake_form
),

with_security as (
    select
        i.*,
        case
            when ss.secure_status = 'Insecure' then true
            when ss.secure_status = 'Secure'   then false
        end as is_insecure_per_answer
    from intmdt i
    left join dw_dev.dev_jkizer_source.map_zentake_security_status_concept ss
        on  i.form_id     = ss.form_id
        and i.question_id = ss.question_id
        and trim(upper(i.answer_concept)) = trim(upper(ss.question_answer))
),

ranked as (
    -- Within a single response, rank the occurrences of each question_concept by
    -- question_position. The Nth occurrence of "Name" is in the same logical row as
    -- the Nth occurrence of "Phone", "Authorized to Involvement", etc.
    select
        *,
        dense_rank() over (
            partition by response_id, question_concept
            order by question_position
        ) as row_position
    from with_security
),

collapsed as (
    -- Multi-select answers within a single row collapse here. Most multi-row forms have
    -- single-select fields per row, but defensive against future use cases.
    select
        suvida_id,
        any_value(customer_elation_id)   as customer_elation_id,
        response_id,
        any_value(form_id)               as form_id,
        any_value(form_name)             as form_name,
        any_value(form_family)           as form_family,
        any_value(form_version)          as form_version,
        any_value(language)              as language,
        any_value(regulatory_state)      as regulatory_state,
        any_value(user_id)               as user_id,
        any_value(user_email)            as user_email,
        any_value(question_id)           as question_id,
        question_concept,
        row_position,
        listagg(distinct answer_concept, ' | ') within group (order by answer_concept) as answer_text,
        array_agg(distinct answer_concept) within group (order by answer_concept)      as answer_array,
        boolor_agg(is_insecure_per_answer) as is_insecure,
        any_value(sent_at_datetime)      as sent_at_datetime,
        any_value(completed_at_datetime) as completed_at_datetime,
        any_value(data_source)           as data_source
    from ranked
    group by suvida_id, response_id, question_concept, row_position
)

select
    md5(cast(coalesce(cast(response_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(row_position as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(question_concept as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as form_response_row_skey,
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
    row_position,
    answer_text,
    answer_array,
    case when array_size(answer_array) = 1 then try_to_number(answer_text) end as answer_numeric,
    -- Mirrors fct_form_response.answer_boolean — same recognized affirmative/negative phrasing.
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
    )
;


  