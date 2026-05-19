--
-- Staged Zentake form responses from the backfill dataset.
-- Covers the gap between when the original zentake_submissions stopped (1/17/26) and when Airbyte began (3/27/2026).
-- One row per form submission.

select
    id as response_id,
    form_id,
    form_name,
    parse_json(patient):external_id::varchar as customer_elation_id,
    parse_json(patient):first_name::varchar as customer_first_name,
    parse_json(patient):last_name::varchar as customer_last_name,
    parse_json(patient):email::varchar as customer_email,
    created_at::timestamp as sent_at_datetime,
    submitted_at::timestamp as completed_at_datetime,
    is_archived as archived
from source_prod.zentake.responses_backfill
-- Deduplicate on response id, keeping the most recently submitted record, as the backfill source contains duplicate rows
qualify row_number() over (partition by id order by submitted_at desc nulls last) = 1