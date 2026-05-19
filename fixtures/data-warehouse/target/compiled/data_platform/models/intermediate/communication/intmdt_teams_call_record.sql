/*
    Intermediate model for Teams call records.

    One row per Teams call id. Flattens the sessions and participants JSON to derive:
      - Clinic attribution (from AA / CQ session phone seed lookup, with displayName
        regex fallback)
      - Voicemail and answered flags
      - Two-level missed-call classification + is_unanswered_clinic_call
      - Caller / callee phone identities at call level
      - Approximate ring_time_seconds

    Less precise than the prior direct-routing model on ring time (no INVITE-level
    timestamps); compensated by session-level routing detail that direct routing did
    not expose.

    Clinic-name coverage gap: seeds/map_teams_semantic_definition.csv currently
    contains the per-clinic Auto Attendant phone numbers; the matching Call Queue
    phone numbers (and a number of non-receiving queues such as Referrals,
    Compliance, NOC, etc.) are not mapped. Where the phone lookup misses, a
    multi-pattern regex on the AA/CQ displayName is used as a fallback. The seed
    should be expanded over time for full clinic coverage.
*/



with calls as (
    select * from dw_prod.dw_staging.stg_teams_call_record
),

sessions as (
    select
        c.id     as call_id,
        s.index  as session_seq,

        try_to_timestamp_ntz(s.value:startDateTime::varchar) as session_start_date_time,
        try_to_timestamp_ntz(s.value:endDateTime::varchar)   as session_end_date_time,

        s.value:callee:identity:user:id::varchar                     as callee_user_id,
        s.value:callee:identity:user:displayName::varchar            as callee_user_display_name,
        s.value:callee:associatedIdentity:userPrincipalName::varchar as callee_user_upn,
        s.value:callee:identity:phone:id::varchar                    as callee_phone,
        s.value:callee:userAgent:role::varchar                       as callee_role,

        s.value:caller:identity:user:id::varchar                     as caller_user_id,
        s.value:caller:associatedIdentity:userPrincipalName::varchar as caller_user_upn,
        s.value:caller:identity:phone:id::varchar                    as caller_phone,
        s.value:caller:userAgent:role::varchar                       as caller_role
    from calls c,
         lateral flatten(input => c.sessions_variant, outer => true) s
),

session_flags as (
    select
        call_id,
        session_seq,
        session_start_date_time,
        callee_phone,
        caller_phone,
        callee_role,
        callee_user_display_name,
        callee_user_upn,

        -- A real Suvidano endpoint on this session — user identity, suvidahealthcare.com
        -- UPN (from associatedIdentity since identity.user.userPrincipalName is never
        -- populated in this source), no service-principal role. Checked on both sides
        -- because Microsoft Graph logs a queue-answered agent as the *caller* of their
        -- subsequent media legs, not as the callee of the inbound leg.
        case
            when callee_user_id is not null
                 and lower(callee_user_upn) like '%@suvidahealthcare.com'
                 and callee_role is null
            then true
            else false
        end as is_suvidano_callee_session,

        case
            when caller_user_id is not null
                 and lower(caller_user_upn) like '%@suvidahealthcare.com'
                 and caller_role is null
            then true
            else false
        end as is_suvidano_caller_session,

        iff(callee_role = 'skypeForBusinessAutoAttendant', true, false) as is_aa_session,
        iff(callee_role = 'skypeForBusinessCallQueues',    true, false) as is_cq_session,
        iff(callee_role = 'voicemail',                     true, false) as is_voicemail_session,

        -- Embedded phone in AA / CQ associated UPN. Most follow
        -- "x15208431596@lunamedholdings.onmicrosoft.com" but some omit the 'x'
        -- prefix (e.g., "13466109271@..."). A broad digit-run match handles both.
        case
            when callee_role in ('skypeForBusinessAutoAttendant', 'skypeForBusinessCallQueues')
            then regexp_substr(callee_user_upn, '([0-9]{10,11})@', 1, 1, 'e', 1)
        end as aa_cq_phone,

        -- Clinic label parsed from AA / CQ displayName. Multiple naming
        -- conventions are in use; try the common patterns in order:
        --   "AA - Care Team - <clinic>" / "CQ - Care Team - <clinic>"
        --   "AA - CT - <clinic>"        / "CQ - CT - <clinic>"
        --   "Care Team - <clinic> Auto Attendant" / "... Call Queue"
        --   "Care Team -  <clinic>" (double-space variant included)
        case when callee_role in ('skypeForBusinessAutoAttendant', 'skypeForBusinessCallQueues')
            then trim(
                regexp_replace(
                    regexp_replace(
                        coalesce(
                            regexp_substr(callee_user_display_name,
                                '^(AA|CQ)\\s*-\\s*(Care Team|CT)\\s*-\\s*(.+)$',
                                1, 1, 'e', 3),
                            regexp_substr(callee_user_display_name,
                                '^Care Team\\s*-\\s*(.+)$',
                                1, 1, 'e', 1)
                        ),
                        '\\s*-?\\s*(Auto Attendant|Call Queue)\\s*$', ''),
                    '\\s*-\\s*$', '')
            )
        end as aa_cq_clinic_label
    from sessions
),

clinic_map as (
    select
        to_varchar(phone_number) as phone_number,
        queue_display_name,
        queue_kind,
        queue_category,
        clinic_name,
        location_id
    from dw_prod.dw_source.map_teams_semantic_definition
),

session_clinic_resolution as (
    select
        sf.call_id,
        sf.session_seq,
        sf.aa_cq_phone,
        sf.aa_cq_clinic_label,
        cm.clinic_name        as clinic_from_phone,
        cm.location_id        as location_id_from_phone,
        cm.queue_category     as category_from_phone,
        cm.queue_display_name as queue_display_name_from_phone
    from session_flags sf
    left join clinic_map cm
        on cm.phone_number = 
    
    case
        when regexp_replace(sf.aa_cq_phone, '[^0-9]', '') = '' then null
        when length(regexp_replace(sf.aa_cq_phone, '[^0-9]', '')) = 11
            and left(regexp_replace(sf.aa_cq_phone, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(sf.aa_cq_phone, '[^0-9]', ''), 10)
        when length(regexp_replace(sf.aa_cq_phone, '[^0-9]', '')) = 10
            then regexp_replace(sf.aa_cq_phone, '[^0-9]', '')
        else null
    end

    where sf.is_aa_session or sf.is_cq_session
),

call_session_summary as (
    select
        call_id,
        boolor_agg(is_suvidano_callee_session) as had_suvidano_callee_session,
        boolor_agg(is_suvidano_caller_session) as had_suvidano_caller_session,
        boolor_agg(is_voicemail_session)       as ended_in_voicemail,
        boolor_agg(is_aa_session)              as had_auto_attendant,
        boolor_agg(is_cq_session)              as had_call_queue,
        min(case when is_suvidano_callee_session or is_suvidano_caller_session
                 then session_start_date_time end)
            as first_suvidano_session_start
    from session_flags
    group by 1
),

call_clinic_resolution as (
    select
        call_id,
        max(clinic_from_phone)                                  as clinic_name_from_phone,
        max(location_id_from_phone)                             as clinic_location_id,
        max(aa_cq_clinic_label)                                 as clinic_name_from_label,
        max(aa_cq_phone)                                        as any_aa_cq_phone,
        max(category_from_phone)                                as aa_cq_queue_category,
        max(queue_display_name_from_phone)                      as aa_cq_queue_display_name,
        boolor_agg(category_from_phone = 'clinic')              as has_clinic_match,
        boolor_agg(category_from_phone = 'main_line')           as has_main_line_match
    from session_clinic_resolution
    group by 1
),

call_phone_identities as (
    select
        call_id,
        max(caller_phone) as session_caller_phone,
        max(case when callee_role is null then callee_phone end) as session_user_callee_phone,
        max(callee_phone) as session_any_callee_phone
    from session_flags
    group by 1
),

raw_numbers as (
    select
        c.id,
        coalesce(c.organizer_phone, cpi.session_caller_phone) as caller_number_raw,
        coalesce(
            case when c.is_organizer_user  then cpi.session_any_callee_phone end,
            case when c.is_organizer_phone then ccr.any_aa_cq_phone end,
            cpi.session_user_callee_phone
        ) as callee_number_raw
    from calls c
    left join call_clinic_resolution ccr on c.id = ccr.call_id
    left join call_phone_identities  cpi on c.id = cpi.call_id
)

select
    c.id,
    c.version,
    c.call_type,
    c.modalities,

    c.start_date_time,
    c.end_date_time,
    c.last_modified_date_time,
    c.duration_seconds,
    iff(c.duration_seconds > 300, true, false) as is_more_than_5_min_call,

    c.is_organizer_phone,
    c.is_organizer_user,
    c.organizer_phone,
    c.organizer_user_id,
    c.organizer_user_display_name,
    c.organizer_user_email,

    -- Direction
    c.is_organizer_phone as is_inbound_call,
    c.is_organizer_user  as is_outbound_call,
    iff(c.is_organizer_phone and coalesce(css.had_auto_attendant, false), true, false) as is_inbound_auto_attend,
    iff(c.is_organizer_user  and coalesce(css.had_auto_attendant, false), true, false) as is_outbound_auto_attend,
    iff(c.call_type = 'groupCall', true, false) as is_conference_call,

    rn.caller_number_raw as caller_number,
    
    
    case
        when regexp_replace(rn.caller_number_raw, '[^0-9]', '') = '' then null
        when length(regexp_replace(rn.caller_number_raw, '[^0-9]', '')) = 11
            and left(regexp_replace(rn.caller_number_raw, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(rn.caller_number_raw, '[^0-9]', ''), 10)
        when length(regexp_replace(rn.caller_number_raw, '[^0-9]', '')) = 10
            then regexp_replace(rn.caller_number_raw, '[^0-9]', '')
        else null
    end
 as caller_number_clean,
    rn.callee_number_raw as callee_number,
    
    
    case
        when regexp_replace(rn.callee_number_raw, '[^0-9]', '') = '' then null
        when length(regexp_replace(rn.callee_number_raw, '[^0-9]', '')) = 11
            and left(regexp_replace(rn.callee_number_raw, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(rn.callee_number_raw, '[^0-9]', ''), 10)
        when length(regexp_replace(rn.callee_number_raw, '[^0-9]', '')) = 10
            then regexp_replace(rn.callee_number_raw, '[^0-9]', '')
        else null
    end
 as callee_number_clean,

    -- Clinic attribution. Phone-seed match first (canonical name matching
    -- dim_location.location_name), then AA/CQ displayName regex fallback
    -- (extracted label — may not match dim_location), then organizer/callee
    -- phone lookups.
    coalesce(
        ccr.clinic_name_from_phone,
        cm_org.clinic_name,
        cm_callee.clinic_name,
        ccr.clinic_name_from_label
    ) as clinic_name,

    coalesce(
        ccr.clinic_location_id,
        cm_org.location_id,
        cm_callee.location_id
    ) as clinic_location_id,

    case
        when ccr.clinic_name_from_phone is not null then 'auto_attendant_phone'
        when cm_org.clinic_name         is not null then 'organizer_phone'
        when cm_callee.clinic_name      is not null then 'callee_phone'
        when ccr.clinic_name_from_label is not null then 'auto_attendant_label'
    end as clinic_name_source,

    -- A call is "clinic" if any phone signal resolves to a queue_category of
    -- 'clinic', or the displayName regex extracts a clinic label from an AA/CQ.
    case
        when coalesce(ccr.has_clinic_match, false)             then true
        when cm_org.queue_category     = 'clinic'              then true
        when cm_callee.queue_category  = 'clinic'              then true
        when ccr.clinic_name_from_label is not null            then true
        else false
    end as is_clinic_call,

    -- AA / CQ queue category for non-clinic contexts (referrals, pharmacy,
    -- compliance, NOC, etc.). Useful for slicing operational queue traffic.
    ccr.aa_cq_queue_category   as aa_cq_queue_category,
    ccr.aa_cq_queue_display_name as aa_cq_queue_display_name,

    -- Caller / callee phone seed enrichment (independent of AA / CQ routing).
    cm_org.queue_display_name    as caller_queue_display_name,
    cm_org.queue_category        as caller_queue_category,
    cm_callee.queue_display_name as callee_queue_display_name,
    cm_callee.queue_category     as callee_queue_category,

    -- For inbound: any Suvidano endpoint (callee with no role = direct answer,
    -- or caller with no role = queue-answered agent's media leg) implies a
    -- Suvidano was on the call. For outbound, the Suvidano is the originator,
    -- so "answered by Suvidano" doesn't apply; set false.
    case
        when c.is_organizer_phone
             and (coalesce(css.had_suvidano_callee_session, false)
                  or coalesce(css.had_suvidano_caller_session, false))
        then true
        else false
    end as was_answered_by_suvidano,

    coalesce(css.ended_in_voicemail, false) as ended_in_voicemail,
    coalesce(css.had_auto_attendant, false) as had_auto_attendant,
    coalesce(css.had_call_queue,     false) as had_call_queue,

    -- Direction-aware "successful" / "missed" call definitions.
    -- Inbound: a Suvidano picked up. Outbound (organizer is a user): the call
    -- lasted long enough to be a real conversation (duration >= 10s). The
    -- outbound check is a heuristic — Teams Graph does not flag patient-side
    -- pickup or voicemail directly.
    case
        when c.is_organizer_user
            then iff(c.duration_seconds >= 10, true, false)
        when c.is_organizer_phone
            then iff(coalesce(css.had_suvidano_callee_session, false)
                     or coalesce(css.had_suvidano_caller_session, false), true, false)
        else false
    end as successful_call,

    case
        when c.is_organizer_user
            then iff(c.duration_seconds < 10, true, false)
        when c.is_organizer_phone
            then iff(coalesce(css.had_suvidano_callee_session, false)
                     or coalesce(css.had_suvidano_caller_session, false), false, true)
        else true
    end as is_missed_call,

    -- Two-level missed-call categorization. Only meaningful for inbound calls,
    -- where the AA / CQ routing and voicemail signals come from Suvida-side
    -- service principals. Null for outbound (no equivalent signals exist on
    -- the patient side).
    case
        when c.is_organizer_user then null
        when coalesce(css.had_suvidano_callee_session, false)
             or coalesce(css.had_suvidano_caller_session, false)
            then 'answered'
        when coalesce(css.ended_in_voicemail, false) then 'voicemail'
        when coalesce(css.had_auto_attendant, false) or coalesce(css.had_call_queue, false)
            then 'abandoned_in_queue'
        else 'abandoned'
    end as missed_call_reason,

    -- Strict: hit a clinic AA / CQ (resolved to a clinic name) and was not
    -- picked up by a Suvidano.
    case
        when (ccr.clinic_name_from_phone is not null or ccr.clinic_name_from_label is not null)
             and coalesce(css.had_suvidano_callee_session, false) = false
             and coalesce(css.had_suvidano_caller_session, false) = false
        then true
        else false
    end as is_unanswered_clinic_call,

    -- Approximate ring time. Originally intended as (call_start →
    -- first Suvidano-session_start), but session-level startDateTime is not
    -- populated in this source, so this currently falls back to total call
    -- duration for every row. For unanswered calls that's effectively the
    -- time spent ringing / in queue before voicemail or abandonment; for
    -- answered calls it includes the conversation. Filter on
    -- is_missed_call / missed_call_reason to scope to unanswered calls
    -- where the value is most meaningful.
    coalesce(
        timestampdiff('second', c.start_date_time, css.first_suvidano_session_start),
        c.duration_seconds
    ) as ring_time_seconds

from calls c
left join call_session_summary    css on c.id = css.call_id
left join call_clinic_resolution  ccr on c.id = ccr.call_id
left join raw_numbers             rn  on c.id = rn.id
left join clinic_map cm_org
    on cm_org.phone_number = 
    
    case
        when regexp_replace(c.organizer_phone, '[^0-9]', '') = '' then null
        when length(regexp_replace(c.organizer_phone, '[^0-9]', '')) = 11
            and left(regexp_replace(c.organizer_phone, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(c.organizer_phone, '[^0-9]', ''), 10)
        when length(regexp_replace(c.organizer_phone, '[^0-9]', '')) = 10
            then regexp_replace(c.organizer_phone, '[^0-9]', '')
        else null
    end

left join clinic_map cm_callee
    on cm_callee.phone_number = 
    
    case
        when regexp_replace(rn.callee_number_raw, '[^0-9]', '') = '' then null
        when length(regexp_replace(rn.callee_number_raw, '[^0-9]', '')) = 11
            and left(regexp_replace(rn.callee_number_raw, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(rn.callee_number_raw, '[^0-9]', ''), 10)
        when length(regexp_replace(rn.callee_number_raw, '[^0-9]', '')) = 10
            then regexp_replace(rn.callee_number_raw, '[^0-9]', '')
        else null
    end
