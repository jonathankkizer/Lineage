

with appointments as (
    select
        suvida_id,
        elation_id,
        concat(rm.first_name, ' ', rm.last_name) as full_name,
        appointment_id,
        appointment_datetime,
        appointment_datetime_utc,
        appointment_datetime_formatted,
        case
            when preferred_language is null then appointment_date_formatted
            when lower(preferred_language) = 'english' then appointment_date_formatted
            when lower(preferred_language) = 'spanish; castilian' then appointment_date_spanish_formatted
            when lower(preferred_language) = 'spanish' then appointment_date_spanish_formatted
            else appointment_datetime_formatted
        end as appointment_date_language_formatted,
        location_name,
        location_full_address,
        location_address,
        location_city,
        location_state,
        location_zip,
        provider_full_name,
        group_id,
        event_id,
        event_delivery_method as delivery_method,
        phone,
        rm.reason,
        preferred_language,
        iff(low_literacy, 1, 0) as low_literacy,
        iff(sms_opt_in, 1, 0) as sms_opt_in,
        iff(lower(event_name) like '%same day%', 1, 0) as same_day,
        message_template_id,
        message_template,
        department,
        visit_mode,
        visit_location,
        virtual_link,
        case
            when lower(trim(preferred_language)) like 'spanish%' and lower(event_name) like '%same day%' then 'handle-call-response-no-confirm-spanish'
            when lower(trim(preferred_language)) = 'english' and lower(event_name) like '%same day' then 'handle-call-response-no-confirm'     
            when lower(trim(preferred_language)) like 'spanish%' then 'handle-call-response-spanish'
            when lower(trim(preferred_language)) = 'english' then 'handle-call-response'
            else 'handle-call-response'
        end as gather_endpoint,
        iff
        (
            lower(trim(preferred_language)) = 'english' or preferred_language is null,
            'Polly.Joanna-Neural',
            null
        ) as voice_model,
        case
            when reason = 'LSMED: Lifestyle Medicine' then 'SuBienestar'
            when reason = 'MOB: Matter of Balance' then 'Matter of Balance'
            else reason
        end as appointment_type_voice_formatted,
        case
            when reason = 'LSMED: Lifestyle Medicine' then 'SuBienestar'
            when reason = 'MOB: Matter of Balance' then 'Matter of Balance'
            else reason
        end as appointment_type
    from dw_dev.dev_jkizer_staging.stg_appointment_reminder rm
    inner join source_prod.sms.patient_appointment_reminders_visit_types vt
        on lower(trim(rm.reason)) = lower(trim(vt.visit_type_name))
    where
        vt.is_enabled = TRUE
)

select
    appointments.*,
    object_construct
    (
        'AppointmentType', appointment_type,
        'AppointmentTypeVoiceFormatted', appointment_type_voice_formatted,
        'Provider', provider_full_name,
        'Address', location_full_address,
        'Street', location_address,
        'CityState', location_city || ', ' || location_state,
        'Postal', regexp_replace(location_zip, '(.)', '\\1 '),
        'Date', appointment_date_language_formatted,
        'Time', ltrim(to_varchar(appointment_datetime, 'HH12:MI AM'), '0'),
        'TimeVoiceFormatted', ltrim(to_varchar(appointment_datetime, 'HH12:MI'), '0') || ', ' || ltrim(to_varchar(appointment_datetime, 'AM'), '0'),
        'ArrivalTime', ltrim(to_varchar(dateadd(minute, -15, appointment_datetime), 'HH12:MI AM'), '0'),
        'ArrivalTimeVoiceFormatted', ltrim(to_varchar(dateadd(minute, -15, appointment_datetime), 'HH12:MI'), '0') || ', ' || ltrim(to_varchar(dateadd(minute, -15, appointment_datetime), 'AM'), '0'),
        'Phone', '+1-888-478-8432',
        'PhoneVoiceFormatted', '1, 8, 8, 8, 4, 7, 8, 8, 4, 3, 2',
        'Link', virtual_link,
        'GatherHandlerUrl', 'https://suvida-automated-appt-reminder-call-service-9596-dev.twil.io' || '/' || gather_endpoint || '?forward_number=' || '+18884788432' || '&appointment_id=' || appointment_id || iff(voice_model is null, '', '&voice=' || voice_model),
        'Voice', coalesce(voice_model, '')
    ) as context
from appointments