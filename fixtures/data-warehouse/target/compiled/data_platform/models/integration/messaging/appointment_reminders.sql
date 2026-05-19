

select
    rm.suvida_id,
    rm.elation_id,
    rm.full_name,
    rm.appointment_id,
    rm.appointment_datetime,
    rm.appointment_datetime_utc,
    rm.appointment_datetime_formatted,
    rm.appointment_date_language_formatted,
    rm.provider_full_name,
    rm.location_name,
    rm.group_id,
    rm.event_id,
    rm.delivery_method,
    rm.phone,
    rm.reason,
    rm.preferred_language,
    rm.low_literacy,
    rm.sms_opt_in,
    rm.same_day,
    rm.department,
    rm.visit_mode,
    rm.virtual_link,
    rm.message_template_id,
    dw_prod.dw.parse_template_v2(
        message_template,
        context
    ) as message,
    case
        when delivery_method = 'SMS' then dw_prod.dw.parse_template_v2(replace(message_template, '\n', ' '), context)
        else null
    end as message_formatted
from dw_dev.dev_jkizer.intmdt_appointment_reminder rm