/*
  Outreach episodes — one row per (suvida_id, cohort_key, episode_id).

  An episode represents one continuous spell of a patient belonging to an outreach cohort.
  A patient who leaves and re-enters the cohort produces a new episode (same suvida_id + cohort_key,
  new episode_id). This preserves full history while keeping each work item independently trackable.

  Open / close logic:
  - opened_at = first snapshot_date in the continuous island
  - Internally, the most recent snapshot_date in the island ("last seen") drives close detection:
    if it is < current_date, the patient has dropped from membership and the episode is closed with
    close_reason='no_longer_eligible' and close_source='system'.
  - Gap detection: any missing snapshot_date inside what would otherwise be one island breaks it
    into two episodes. (Note: if dbt fails to run for a day, this can spuriously split episodes.)

  Staff-driven closes (declined, unreachable, etc.) are out of scope for v1 — they will land
  from Airtable in a future PR and will override the system close logic for affected episodes.
*/



with membership as (
    select
        suvida_id,
        cohort_key,
        snapshot_date
    from dw_dev.dev_jkizer.int_outreach_episode_snapshot
),

flagged as (
    select
        suvida_id,
        cohort_key,
        snapshot_date,
        case
            when lag(snapshot_date) over (
                    partition by suvida_id, cohort_key
                    order by snapshot_date
                 ) is null
                or datediff('day',
                        lag(snapshot_date) over (
                            partition by suvida_id, cohort_key
                            order by snapshot_date
                        ),
                        snapshot_date
                   ) > 1
            then 1
            else 0
        end as is_new_episode
    from membership
),

episode_groups as (
    select
        suvida_id,
        cohort_key,
        snapshot_date,
        sum(is_new_episode) over (
            partition by suvida_id, cohort_key
            order by snapshot_date
            rows between unbounded preceding and current row
        ) as episode_seq
    from flagged
),

episode_spans as (
    select
        suvida_id,
        cohort_key,
        min(snapshot_date) as opened_at,
        max(snapshot_date) as last_seen_at
    from episode_groups
    group by suvida_id, cohort_key, episode_seq
),

final as (
    select
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cohort_key as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(opened_at as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as episode_id,
        suvida_id,
        cohort_key,
        opened_at,
        case when last_seen_at < current_date then current_date end as closed_at,
        case when last_seen_at < current_date then 'no_longer_eligible' end as close_reason,
        case when last_seen_at < current_date then 'system' end as close_source,
        case when last_seen_at < current_date then 'closed' else 'open' end as current_status
    from episode_spans
),

with_skey as (
    select
        *,
        md5(cast(coalesce(cast(closed_at as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(close_reason as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(close_source as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(current_status as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey
    from final
)

select * from with_skey