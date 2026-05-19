
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_relay_referral_order
  
  copy grants
  
  
  as (
    with parsed as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _ab_source_file_url,
        _ab_source_file_last_modified,
        data:envelope:eventType::varchar as event_type,
        data:envelope:eventTime::timestamp_tz as event_time,
        parse_json(data:envelope:data::varchar):data as payload,
        data as data_variant
    from airbyte_source_prod.elation_relay_referrals.referrals
), exploded as (
    select
        payload:id::number as referral_id,
        to_varchar(payload:patient::number) as elation_id,
        payload:practice::number as practice_id,
        payload:letter::number as letter_id,
        payload:authorization_for::varchar as authorization_for,
        payload:authorization_for_short::varchar as authorization_for_short,
        payload:auth_number::varchar as auth_number,
        payload:consultant_name::varchar as consultant_name,
        payload:short_consultant_name::varchar as short_consultant_name,
        try_to_date(payload:date_for_re_eval::varchar) as date_for_re_eval,
        payload:referral_letter:id::number as referral_letter_id,
        payload:referral_letter:delivery_date::timestamp_tz as referral_letter_delivery_datetime,
        payload:referral_letter:sign_date::timestamp_tz as referral_letter_sign_datetime,
        payload:resolution:id::number as resolution_id,
        payload:resolution:state::varchar as resolution_state,
        payload:resolution:document::number as resolution_document_id,
        payload:resolution:resolving_document::number as resolution_resolving_document_id,
        payload:resolution:note::varchar as resolution_note,
        payload:resolution:created_date::timestamp_tz as resolution_created_datetime,
        payload:resolution:deleted_date::timestamp_tz as resolution_deleted_datetime,
        payload:created_date::timestamp_tz as created_datetime,
        payload:deleted_date::timestamp_tz as deleted_datetime,
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
  );

