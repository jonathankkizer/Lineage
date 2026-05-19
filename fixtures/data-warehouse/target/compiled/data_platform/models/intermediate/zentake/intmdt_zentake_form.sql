--
-- Description: Unified Zentake form responses across all three ingestion sources.
--
-- Purpose: source_prod.zentake stopped refreshing in Jan 2026 when Suvida migrated to Airbyte
--          (airbyte_source_prod.zentake, live from 3/27/2026). Backfill tables in source_prod.zentake
--          cover the gap. This model unions all three so downstream consumers require no changes.
--          When the same response appears in multiple sources, airbyte > backfill > legacy.
--
-- Grain: One row per response per question per answer choice.
--
-- form_family / form_version / language / regulatory_state are joined from
-- map_zentake_form_family on form_id. Consumers should filter on form_family for durability
-- across Zentake form-version churn — form_name LIKE patterns are fragile (the 11 legacy
-- consent_*_form_ind columns derived from form_name were removed in the 2026 refactor).
--

with all_submissions as (
    select
        *,
        'legacy' as data_source
    from dw_dev.dev_jkizer_staging.stg_zentake_form

    union all

    select
        *,
        'backfill' as data_source
    from dw_dev.dev_jkizer.intmdt_zentake_backfill_form

    union all

    select
        *,
        'airbyte' as data_source
    from dw_dev.dev_jkizer.intmdt_zentake_airbyte_form
),

-- Partitioned by response_id (one form submission), question_id (one question on that form),
-- and stand_answer (the concept-mapped answer value).
-- The prevents duplicate rows when English and Spanish answer choices map to the same concept.
-- When the same response appears in multiple sources, airbyte wins over backfill over legacy.
deduped as (
    select *
    from all_submissions
    qualify row_number() over (
        partition by response_id, question_id, stand_answer
        order by case data_source when 'airbyte' then 1 when 'backfill' then 2 else 3 end
    ) = 1
),

-- Resolve suvida_id by joining to the identity walk tables on customer_elation_id.
-- Filters to non-deleted records with a known Elation ID.
resolve_suvida_id as (
    select
        coalesce(idw.suvida_id, simew.suvida_id) as suvida_id,
        deduped.customer_elation_id,
        deduped.response_id,
        deduped.form_id,
        deduped.form_name,
        deduped.user_id,
        deduped.user_email,
        deduped.sent_at_datetime,
        deduped.completed_at_datetime,
        deduped.question_id,
        deduped.question_position,
        deduped.stand_question,
        deduped.stand_answer,
        deduped.data_source
    from deduped
    left join dw_dev.dev_jkizer.suvida_id_walk idw
        on idw.member_id = deduped.customer_elation_id
        and idw.source = 'Elation'
    left join dw_dev.dev_jkizer.suvida_id_master_elation_walk simew
        on deduped.customer_elation_id = simew.elation_id
        and simew.source = 'Elation'
    where deduped.is_deleted = 0
    and deduped.customer_elation_id is not null
    -- Collapse fan-out from suvida_id_master_elation_walk returning multiple rows per elation_id.
    -- Prefer rows where suvida_id_walk resolved a match (idw.suvida_id not null) over the fallback.
    qualify row_number() over (
        partition by deduped.response_id, deduped.question_id, deduped.stand_answer
        order by idw.suvida_id nulls last
    ) = 1
)

select
    r.suvida_id,
    r.customer_elation_id,
    r.response_id,
    r.form_id,
    r.form_name,
    ff.form_family,
    ff.form_version,
    ff.language,
    ff.regulatory_state,
    r.user_id,
    r.user_email,
    r.sent_at_datetime,
    r.completed_at_datetime,
    r.question_id,
    r.question_position,
    r.stand_question as question,
    r.stand_answer   as answer,
    r.data_source
from resolve_suvida_id r
left join dw_dev.dev_jkizer_source.map_zentake_form_family ff
    on  ff.form_id = r.form_id
    -- form_name_pattern disambiguates when a single form_id has been reused for multiple
    -- form_names (e.g., 10c94b47 — Consent for Third Party Involvement vs Patient
    -- Provider/Specialist List). Null pattern means no constraint (matches any form_name).
    and (ff.form_name_pattern is null or ff.form_name_pattern = '' or r.form_name ilike ff.form_name_pattern)
-- Prefer specific form_name_pattern over null/empty fallback so a future collision with both
-- specific and null rows won't fan out.
qualify row_number() over (
    partition by r.response_id, r.question_id, r.stand_answer
    order by iff(ff.form_name_pattern is null or ff.form_name_pattern = '', 1, 0)
) = 1