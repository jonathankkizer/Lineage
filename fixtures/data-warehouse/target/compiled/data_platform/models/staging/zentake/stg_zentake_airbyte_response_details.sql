--
-- Staged Zentake response details from the Airbyte ingestion path.
-- One row per question per answer choice. Unanswered questions are preserved as null via outer => true.
-- Airbyte source began writing data on 3/27/2026.
--
-- question_position is the array index of each question within the response's `answers` array.
-- Used downstream by fct_form_response_row to derive row_position for multi-row forms.
--
-- question_answer coalesces from two JSON paths: the answer_choices array (for select-type
-- questions — Yes/No, dropdowns, multi-select) and the top-level answer_text (for free-text
-- questions — Name, Phone, free-form fields). Previously only the answer_choices path was
-- extracted, which silently dropped free-text answers.
--

select
    rd.id                                                       as response_id,
    rd.user:id::varchar                                         as user_id,
    rd.user:email::varchar                                      as user_email,
    af.index                                                    as question_position,
    af.value:question:id::varchar                               as question_id,
    af.value:question:text::varchar                             as question_text,
    coalesce(
        acf.value:question_choice:text_value::varchar,
        af.value:answer_text::varchar
    )                                                           as question_answer
from airbyte_source_prod.zentake.response_details rd,
lateral flatten(input => rd.answers) af,
-- outer => true preserves questions with no answer choices as a null row rather than dropping them
lateral flatten(input => af.value:answer_choices, outer => true) acf
where af.value:question:id::varchar is not null
-- Deduplicate to handle cases where a question appears with both a null answer choice and an outer => true null row
qualify row_number() over (
    partition by rd.id, af.value:question:id::varchar,
        coalesce(acf.value:question_choice:text_value::varchar, af.value:answer_text::varchar)
    order by 1
) = 1