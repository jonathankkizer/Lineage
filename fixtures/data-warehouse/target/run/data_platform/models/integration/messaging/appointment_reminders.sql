
  create or replace   view dw_dev.dev_jkizer.appointment_reminders
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$The patient's Suvida identifier$$, 
  
    "ELATION_ID" COMMENT $$The patient's EMR (Elation) identifier$$, 
  
    "FULL_NAME" COMMENT $$$$, 
  
    "APPOINTMENT_ID" COMMENT $$The appointment EMR (Elation) identifier$$, 
  
    "APPOINTMENT_DATETIME" COMMENT $$The appointment date/time in the local timezone$$, 
  
    "APPOINTMENT_DATETIME_UTC" COMMENT $$The appointment date/time in UTC$$, 
  
    "APPOINTMENT_DATETIME_FORMATTED" COMMENT $$$$, 
  
    "APPOINTMENT_DATE_LANGUAGE_FORMATTED" COMMENT $$$$, 
  
    "PROVIDER_FULL_NAME" COMMENT $$The appointment provider's full name (first + last + credentials)$$, 
  
    "LOCATION_NAME" COMMENT $$$$, 
  
    "GROUP_ID" COMMENT $$The group identifier for the reminder.  Groups are based on the department (specialty), the location (virtual, virtual-in-center, in person etc.) and the language (English, Spanish; Castilian etc.)$$, 
  
    "EVENT_ID" COMMENT $$The event identifier.$$, 
  
    "DELIVERY_METHOD" COMMENT $$$$, 
  
    "PHONE" COMMENT $$The patient's phone number$$, 
  
    "REASON" COMMENT $$The appointment reason (type)$$, 
  
    "PREFERRED_LANGUAGE" COMMENT $$The patient's preferred language$$, 
  
    "LOW_LITERACY" COMMENT $$$$, 
  
    "SMS_OPT_IN" COMMENT $$$$, 
  
    "SAME_DAY" COMMENT $$$$, 
  
    "DEPARTMENT" COMMENT $$The appointment department (specialty)$$, 
  
    "VISIT_MODE" COMMENT $$The appointment visit mode (In Person or Video)$$, 
  
    "VIRTUAL_LINK" COMMENT $$The appointment's virtual meeting link (if the appointment is a VIDEO appointment)$$, 
  
    "MESSAGE_TEMPLATE_ID" COMMENT $$The appointment reminder message template identifier$$, 
  
    "MESSAGE" COMMENT $$$$, 
  
    "MESSAGE_FORMATTED" COMMENT $$$$
  
)

  copy grants
  
  
  as (
    

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
  );

