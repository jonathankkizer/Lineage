with parsed as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        data:envelope:eventType::varchar as event_type,
        data:envelope:eventTime::timestamp_tz as event_time,
        data:envelope:unwrapped:id::number as referral_id,
        data:envelope:unwrapped:icd10_codes as icd10_codes_variant
    from airbyte_source_prod.elation_relay_referrals.referrals
), latest_event as (
    select
        referral_id,
        icd10_codes_variant,
        event_time,
        _airbyte_extracted_at
    from parsed
    where event_type not ilike '%Deleted'
    qualify row_number() over (
        partition by referral_id
        order by event_time desc, _airbyte_extracted_at desc
    ) = 1
), flattened as (
    select
        le.referral_id,
        f.value:code::varchar as icd_10_code,
        f.value:description::varchar as icd_10_code_description,
        le.event_time,
        le._airbyte_extracted_at
    from latest_event le,
        lateral flatten(input => le.icd10_codes_variant, outer => false) f
)
select
    referral_id,
    icd_10_code,
    icd_10_code_description,
    event_time,
    _airbyte_extracted_at,
    row_number() over (
        partition by referral_id, icd_10_code
        order by event_time desc
    ) as _idx
from flattened