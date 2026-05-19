--
-- Intermediate model joining Zentake backfill staging tables and applying question/answer concept standardization.
-- Table grain is one row per response per question per answer choice.
-- Covers the gap between when the original zentake_submissions stopped (1/17/26) and when Airbyte began (3/27/2026).
--

-- Join responses to response details and map raw question text to a standardized concept via map_zentake_question_concept.
-- Zentake forms exist in both English and Spanish, so the same question can appear with different phrasing depending on
-- which version of the form was completed. The concept mapping collapses these variants into a single canonical question name,
-- enabling consistent aggregation and gap analysis across language versions. Falls back to raw question_text if no mapping exists.
with standardize_question as (
    select
        r.response_id,
        r.form_id,
        r.form_name,
        d.user_id,
        d.user_email,
        r.customer_elation_id,
        r.customer_first_name,
        r.customer_last_name,
        r.customer_email,
        r.sent_at_datetime,
        r.completed_at_datetime,
        r.archived,
        d.question_id,
        d.question_position,
        d.question_text,
        d.question_answer,
        coalesce(mzqc.question_concept, d.question_text) as stand_question,
        date(r.completed_at_datetime) as report_date
    from dw_dev.dev_jkizer_staging.stg_zentake_backfill_responses r
    inner join dw_dev.dev_jkizer_staging.stg_zentake_backfill_response_details d
        on r.response_id = d.response_id
    left join dw_dev.dev_jkizer_source.map_zentake_question_concept mzqc
        on d.question_text = mzqc.question_text
        and d.question_id = mzqc.question_id
        and r.form_id = mzqc.form_id
        and r.form_name = mzqc.form_name
),

-- Map raw answer text to a standardized concept via map_zentake_answer_concept.
-- Applies the same multilingual normalization as the question mapping — English and Spanish answer choices
-- are collapsed to a single canonical answer value. Falls back to the raw answer text if no mapping exists.
standardize_answer as (
    select
        sq.*,
        coalesce(dzac.answer_concept, sq.question_answer) as stand_answer
    from standardize_question sq
    left join dw_dev.dev_jkizer_source.map_zentake_answer_concept dzac
        on sq.question_answer = dzac.question_answer
        and sq.form_id = dzac.form_id
        and sq.question_id = dzac.question_id
        and sq.form_name = dzac.form_name
        and sq.question_text = dzac.question_text
)

select
    response_id,
    form_id,
    form_name,
    user_id,
    user_email,
    null as customer_id,
    customer_elation_id,
    customer_first_name,
    customer_last_name,
    customer_email,
    sent_at_datetime,
    completed_at_datetime,
    archived,
    question_id,
    question_text,
    stand_question,
    question_answer,
    stand_answer,
    false as is_deleted,
    report_date,
    question_position
from standardize_answer