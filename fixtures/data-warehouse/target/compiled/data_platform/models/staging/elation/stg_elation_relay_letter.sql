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
    from airbyte_source_prod.elation_relay_letters.letters
), exploded as (
    select
        unwrapped:id::number as letter_id,
        to_varchar(unwrapped:patient::number) as patient_id,
        unwrapped:practice::number as practice_id,
        unwrapped:referral_order::number as referral_order_id,
        unwrapped:letter_type::varchar as letter_type,
        unwrapped:send_to_contact:id::number as send_to_contact_id,
        unwrapped:send_to_contact:first_name::varchar as recipient_first_name,
        unwrapped:send_to_contact:middle_name::varchar as recipient_middle_name,
        unwrapped:send_to_contact:last_name::varchar as recipient_last_name,
        unwrapped:send_to_contact:npi::varchar as recipient_npi,
        unwrapped:send_to_contact:org_name::varchar as recipient_org_name,
        unwrapped:send_to_contact:specialties as send_to_contact_specialties_variant,
        unwrapped:send_to_elation_user::number as send_to_elation_user_id,
        unwrapped:send_to_name::varchar as send_to_name,
        unwrapped:send_to_access_user_id::number as send_to_access_user_id,
        unwrapped:display_to::varchar as display_to,
        unwrapped:subject::varchar as subject,
        unwrapped:body::varchar as body,
        unwrapped:to_number::varchar as to_number,
        unwrapped:fax_to::varchar as fax_to,
        unwrapped:fax_status::varchar as fax_status,
        unwrapped:fax_attachments::boolean as fax_attachments,
        unwrapped:delivery_method::varchar as delivery_method,
        unwrapped:delivery_date::timestamp_tz as delivery_datetime,
        unwrapped:direct_message_to::varchar as direct_message_to,
        unwrapped:direct_message_status::varchar as direct_message_status,
        unwrapped:email_to::varchar as email_to,
        unwrapped:viewed_at::timestamp_tz as viewed_at,
        unwrapped:with_archive::boolean as with_archive,
        unwrapped:is_processed::boolean as is_processed,
        unwrapped:failure_unacknowledged::varchar as failure_unacknowledged,
        unwrapped:sign_date::timestamp_tz as sign_datetime,
        unwrapped:signed_by::number as signed_by_user_id,
        unwrapped:document_date::timestamp_tz as document_datetime,
        unwrapped:created_date::timestamp_tz as created_datetime,
        unwrapped:deleted_date::timestamp_tz as deleted_datetime,
        unwrapped:attachments as attachments_variant,
        unwrapped:tags as tags_variant,
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