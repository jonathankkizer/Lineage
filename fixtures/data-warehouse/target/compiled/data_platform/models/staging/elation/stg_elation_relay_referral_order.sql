with parsed as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _ab_source_file_url,
        _ab_source_file_last_modified,
        data:envelope:eventType::varchar as event_type,
        data:envelope:eventTime::timestamp_tz as event_time,
        data:envelope:unwrapped as unwrapped,
        data as data_variant
    from airbyte_source_prod.elation_relay_referrals.referrals
), exploded as (
    select
        unwrapped:id::number as referral_id,
        to_varchar(unwrapped:patient::number) as elation_id,
        unwrapped:practice::number as practice_id,
        unwrapped:letter::number as letter_id,
        unwrapped:authorization_for::varchar as authorization_for,
        unwrapped:authorization_for_short::varchar as authorization_for_short,
        unwrapped:auth_number::varchar as auth_number,
        unwrapped:consultant_name::varchar as consultant_name,
        unwrapped:short_consultant_name::varchar as short_consultant_name,
        coalesce(
            try_to_date(unwrapped:date_for_re_eval::varchar),
            try_to_date(unwrapped:date_for_reEval::varchar)
        ) as date_for_re_eval,
        unwrapped:sign_date::timestamp_tz as sign_datetime,
        unwrapped:signed_by::number as signed_by_user_id,
        unwrapped:specialty:id::number as specialty_id,
        unwrapped:specialty:name::varchar as specialty_name,
        unwrapped:specialty:abbreviation::varchar as specialty_abbreviation,
        unwrapped:specialty:category:id::number as specialty_category_id,
        unwrapped:specialty:category:name::varchar as specialty_category_name,
        unwrapped:icd10_codes as icd10_codes_variant,
        unwrapped:referral_letter:id::number as referral_letter_id,
        unwrapped:referral_letter:delivery_date::timestamp_tz as referral_letter_delivery_datetime,
        unwrapped:referral_letter:sign_date::timestamp_tz as referral_letter_sign_datetime,
        unwrapped:resolution:id::number as resolution_id,
        unwrapped:resolution:state::varchar as resolution_state,
        unwrapped:resolution:document::number as resolution_document_id,
        unwrapped:resolution:resolving_document::number as resolution_resolving_document_id,
        unwrapped:resolution:note::varchar as resolution_note,
        unwrapped:resolution:created_date::timestamp_tz as resolution_created_datetime,
        unwrapped:resolution:deleted_date::timestamp_tz as resolution_deleted_datetime,
        unwrapped:created_date::timestamp_tz as created_datetime,
        unwrapped:deleted_date::timestamp_tz as deleted_datetime,
        event_type,
        event_time,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _ab_source_file_url,
        _ab_source_file_last_modified,
        data_variant
    from parsed
)
select
    *,
    case when event_type ilike '%Deleted' then 1 else 0 end as _is_deleted_event,
    max(case when event_type ilike '%Deleted' then 1 else 0 end)
        over (partition by referral_id) as is_deleted,
    row_number() over (
        partition by referral_id
        order by case when event_type ilike '%Deleted' then 1 else 0 end asc,
                 event_time desc,
                 _airbyte_extracted_at desc
    ) as _idx
from exploded