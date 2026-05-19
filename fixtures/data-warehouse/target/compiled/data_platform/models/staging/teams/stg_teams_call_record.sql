/*
    Staging for the Microsoft Graph callRecords resource (source: teams.call_record).
    One row per Teams call id (latest version). Top-level fields and organizer identity
    are parsed here; participants and sessions are exposed as raw variants for the
    intermediate layer to flatten.

    Replaces the prior direct-routing source (src_graph_direct_routing_call_records),
    which is retained in sources.yml but no longer powers this model. The Graph call
    record provides session-level auto-attendant / call queue routing and voicemail
    signals that direct routing does not expose.
*/

with deduped as (
    select
        id,
        version,
        type,
        modalities,
        start_date_time,
        end_date_time,
        last_modified_date_time,
        join_web_url,
        organizer,
        participants,
        sessions
    from source_prod.teams.call_record
    qualify row_number() over (
        partition by id
        order by version desc, last_modified_date_time desc
    ) = 1
)

select
    id,
    version,
    type as call_type,
    modalities,

    to_timestamp_ntz(start_date_time) as start_date_time,
    to_timestamp_ntz(end_date_time) as end_date_time,
    to_timestamp_ntz(last_modified_date_time) as last_modified_date_time,

    timestampdiff(
        'second',
        to_timestamp_ntz(start_date_time),
        to_timestamp_ntz(end_date_time)
    ) as duration_seconds,

    join_web_url,

    -- Organizer can be either a phone identity (inbound PSTN) or a user identity
    -- (outbound from a Suvidano).
    organizer:identity:phone:id::varchar               as organizer_phone,
    organizer:identity:user:id::varchar                as organizer_user_id,
    organizer:identity:user:displayName::varchar       as organizer_user_display_name,
    organizer:identity:user:userPrincipalName::varchar as organizer_user_email,

    iff(organizer:identity:phone is not null, true, false) as is_organizer_phone,
    iff(organizer:identity:user  is not null, true, false) as is_organizer_user,

    participants as participants_variant,
    sessions     as sessions_variant
from deduped