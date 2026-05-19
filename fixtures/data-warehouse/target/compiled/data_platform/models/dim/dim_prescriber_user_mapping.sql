-- Pre-computed mapping of prescriber names to EHR user IDs

with distinct_prescribers as (
    -- Get unique prescriber names from med adherence data for current year
    select distinct
        prescriber_name
    from dw_dev.dev_jkizer.intmdt_med_adherence
    where prescriber_name is not null
        and trim(prescriber_name) != ''
        and measure_year = date_trunc(year, current_date())
),

ehr_users as (
    -- Get all active EHR users
    select
        user_id,
        replace(user_name, 'MD ', '') as user_name, 
        user_last_name || ', ' || user_first_name as full_user_name,
        user_first_name,
        user_last_name
    from dw_dev.dev_jkizer.ehr_user
    where user_name not like '%,'
),

exact_matches as (
    -- Step 1: Try exact string matches first (most efficient)
    select
        dp.prescriber_name,
        usr.user_id,
        usr.user_name,
        'exact' as match_type,
        1 as match_priority
    from distinct_prescribers dp
    inner join ehr_users usr
        on (
            dp.prescriber_name = usr.user_name
            or dp.prescriber_name = usr.full_user_name
        )
),

fuzzy_matches as (
    -- Step 2: Use fuzzy matching for remaining unmatched names
    select
        dp.prescriber_name,
        usr.user_id,
        usr.user_name,
        'fuzzy' as match_type,
        2 as match_priority,
        greatest(
            jarowinkler_similarity(usr.user_name, dp.prescriber_name),
            jarowinkler_similarity(usr.full_user_name, dp.prescriber_name)
        ) as similarity_score
    from distinct_prescribers dp
    left join exact_matches em
        on dp.prescriber_name = em.prescriber_name
    inner join ehr_users usr
        on (
            jarowinkler_similarity(usr.user_name, dp.prescriber_name) > 92
            or jarowinkler_similarity(usr.full_user_name, dp.prescriber_name) > 92
        )
    where em.prescriber_name is null -- Only match names that didn't have exact matches
    qualify row_number() over (partition by dp.prescriber_name order by similarity_score desc) = 1
),

all_matches as (
    -- Combine exact and fuzzy matches
    select
        prescriber_name,
        user_id,
        user_name,
        match_type,
        match_priority,
        null as similarity_score
    from exact_matches

    union all

    select
        prescriber_name,
        user_id,
        user_name,
        match_type,
        match_priority,
        similarity_score
    from fuzzy_matches
)

select
    prescriber_name,
    user_id,
    user_name,
    match_type,
    similarity_score
from all_matches
-- If somehow there are duplicates, pick the best match
qualify row_number() over (partition by prescriber_name order by match_priority, similarity_score desc nulls last) = 1