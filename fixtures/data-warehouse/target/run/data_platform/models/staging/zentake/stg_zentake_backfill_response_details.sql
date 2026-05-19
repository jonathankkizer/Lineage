
  create or replace   view dw_dev.dev_jkizer_staging.stg_zentake_backfill_response_details
  
  copy grants
  
  
  as (
    --
-- Staged Zentake response details from the backfill dataset.
-- Covers the gap between when the original zentake_submissions stopped (1/17/26) and when Airbyte began (3/27/2026).
-- One row per question per answer choice. Unanswered questions are preserved as null via outer => true.
--
-- See stg_zentake_airbyte_response_details for notes on question_position and the free-text
-- answer extraction via the answer_text coalesce.
--

select
    rd.id                                                       as response_id,
    parse_json(rd.user):id::varchar                             as user_id,
    parse_json(rd.user):email::varchar                          as user_email,
    af.index                                                    as question_position,
    af.value:question:id::varchar                               as question_id,
    af.value:question:text::varchar                             as question_text,
    coalesce(
        acf.value:question_choice:text_value::varchar,
        af.value:answer_text::varchar
    )                                                           as question_answer
from source_prod.zentake.response_details_backfill rd,
lateral flatten(input => parse_json(rd.answers)) af,
lateral flatten(input => af.value:answer_choices, outer => true) acf
where af.value:question:id::varchar is not null
qualify row_number() over (
    partition by rd.id, af.value:question:id::varchar,
        coalesce(acf.value:question_choice:text_value::varchar, af.value:answer_text::varchar)
    order by 1
) = 1
  );

