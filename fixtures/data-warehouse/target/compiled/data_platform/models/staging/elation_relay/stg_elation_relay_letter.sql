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
    from airbyte_source_prod.elation_relay_letters.letters
), exploded as (
    select
        payload:id::number as letter_id,
        to_varchar(payload:patient::number) as patient_id,
        payload:practice::number as practice_id,
        payload:letter_type::varchar as letter_type,
        payload:send_to_contact:id::number as send_to_contact_id,
        payload:send_to_contact:first_name::varchar as recipient_first_name,
        payload:send_to_contact:middle_name::varchar as recipient_middle_name,
        payload:send_to_contact:last_name::varchar as recipient_last_name,
        payload:send_to_contact:npi::varchar as recipient_npi,
        payload:send_to_contact:org_name::varchar as recipient_org_name,
        payload:send_to_contact:specialties as send_to_contact_specialties_variant,
        payload:send_to_elation_user::number as send_to_elation_user_id,
        payload:send_to_name::varchar as send_to_name,
        payload:send_to_access_user_id::number as send_to_access_user_id,
        payload:display_to::varchar as display_to,
        payload:subject::varchar as subject,
        payload:body::varchar as body,
        payload:to_number::varchar as to_number,
        payload:fax_to::varchar as fax_to,
        payload:fax_status::varchar as fax_status,
        payload:fax_attachments::boolean as fax_attachments,
        payload:delivery_method::varchar as delivery_method,
        payload:delivery_date::timestamp_tz as delivery_datetime,
        payload:direct_message_to::varchar as direct_message_to,
        payload:email_to::varchar as email_to,
        payload:viewed_at::timestamp_tz as viewed_at,
        payload:with_archive::boolean as with_archive,
        payload:is_processed::boolean as is_processed,
        payload:failure_unacknowledged::varchar as failure_unacknowledged,
        payload:sign_date::timestamp_tz as sign_datetime,
        payload:signed_by::number as signed_by_user_id,
        payload:document_date::timestamp_tz as document_datetime,
        payload:created_date::timestamp_tz as created_datetime,
        payload:deleted_date::timestamp_tz as deleted_datetime,
        payload:attachments as attachments_variant,
        payload:tags as tags_variant,
        event_type,
        event_time,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _ab_source_file_url,
        _ab_source_file_last_modified,
        data_variant
    from parsed
), with_first_specialty as (
    select
        *,
        get(send_to_contact_specialties_variant, 0):id::number as recipient_specialty_id,
        get(send_to_contact_specialties_variant, 0):name::varchar as recipient_specialty
    from exploded
)
select
    *,
    case when event_type ilike '%Deleted' then 1 else 0 end as _is_deleted_event,
    max(case when event_type ilike '%Deleted' then 1 else 0 end)
        over (partition by letter_id) as is_deleted,
    row_number() over (
        partition by letter_id
        order by case when event_type ilike '%Deleted' then 1 else 0 end asc,
                 event_time desc,
                 _airbyte_extracted_at desc
    ) as _idx
from with_first_specialty