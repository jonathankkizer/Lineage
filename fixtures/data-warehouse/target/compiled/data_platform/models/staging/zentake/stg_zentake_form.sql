--
-- Description: Staged Zentake form responses from the original source_prod.zentake ingestion.
--
-- Purpose: Cleans and standardizes the raw flat submission table, applies question and answer
--          concept mapping to collapse English/Spanish variants, and splits multi-value answers
--          into one row per answer choice. Stopped refreshing in January 2026 — superseded by
--          the Airbyte ingestion. Consumed by intmdt_zentake_form via the 'legacy' union branch.
--
-- Grain: One row per response per question per answer choice.
--

with mapping_raw_zentake as (
	select
		distinct -- This needs to be fixed in data ingestion
		response_id,
		form_id,
		form_name,
		user_id,
		user_email,
		customer_id,
		customer_elation_id,
		customer_first_name,
		customer_last_name,
		customer_email,
		to_timestamp(replace(sent_at, ' at ', ' ')) as sent_at_datetime,
		to_timestamp(replace(completed_at, ' at ', ' ')) as completed_at_datetime,
		archived,
		question_id,
		question_text,
		question_answer,
		iff(question_text like '%DELETED%', true, false) as is_deleted,
		-- question_position for legacy is best-effort: derived from Snowflake's natural
		-- storage order within each response. Used downstream by fct_form_response_row
		-- to pair multi-row form answers (e.g., Third Party Involvement's per-row Y/N).
		-- Reliability caveat: legacy storage order is generally consistent but not
		-- guaranteed across rebuilds. Airbyte/backfill use af.index from JSON, which is
		-- deterministic. See option-A signoff in the 2026 Zentake refactor.
		row_number() over (partition by response_id order by null) as question_position
	from source_prod.zentake.tbl_prod_zentake_submissions
), standardize_question as (  -- Mapping original questions (English and Spanish) to the standar question
	select 
		oz.*,
		coalesce(mzqc.question_concept, oz.question_text) as stand_question,
		date(oz.completed_at_datetime) as report_date
		from mapping_raw_zentake oz
	left join dw_dev.dev_jkizer_source.map_zentake_question_concept mzqc
		on oz.question_text = mzqc.question_text and oz.question_id = mzqc.question_id and oz.form_id = mzqc.form_id and oz.form_name = mzqc.form_name
), separate_answer as ( -- Answer can have multiples values separate by "" this break those into new rows and includes unanswer as "Null"  
	select 
		sq.*,
		trim(value) as sp_answer, 
		index as ordinal
	from standardize_question sq, lateral split_to_table(sq.question_answer, '')
	
	union all
	
	select 
		sq.*,
		null as sp_answer,
		null as ordinal
	from standardize_question sq
	where sq.question_answer is null
), standardize_answer as ( -- Mapping original answer (English and Spanish) to the standar answer
	select                 
		separate_answer.*,
		coalesce(dzac.answer_concept, separate_answer.sp_answer) as stand_answer
	from separate_answer 
	left join dw_dev.dev_jkizer_source.map_zentake_answer_concept dzac
		on separate_answer.sp_answer = dzac.question_answer and separate_answer.form_id = dzac.form_id and separate_answer.question_id = dzac.question_id and separate_answer.form_name = dzac.form_name and separate_answer.question_text = dzac.question_text
)
select --Select the final columns for this model
	lj.response_id,
	lj.form_id, 
	lj.form_name, 
	lj.user_id,
	lj.user_email,
	lj.customer_id, 
	lj.customer_elation_id, 
	lj.customer_first_name, 
	lj.customer_last_name, 
	lj.customer_email, 
	lj.sent_at_datetime, 
	lj.completed_at_datetime, 
	lj.archived, 
	lj.question_id, 
	lj.question_text, 
	lj.stand_question, 
	lj.question_answer, 
	lj.stand_answer, 
	lj.is_deleted,
	lj.report_date,
	lj.question_position
from standardize_answer lj