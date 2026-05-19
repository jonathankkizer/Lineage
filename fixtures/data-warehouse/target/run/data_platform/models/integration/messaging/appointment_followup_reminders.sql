
  create or replace   view dw_dev.dev_jkizer.appointment_followup_reminders
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$The patient's Suvida identifier$$, 
  
    "ELATION_ID" COMMENT $$The patient's EMR (Elation) identifier$$, 
  
    "FIRST_NAME" COMMENT $$The patient's first name$$, 
  
    "LAST_NAME" COMMENT $$The patient's last name$$, 
  
    "PHONE" COMMENT $$The patient's phone number$$, 
  
    "PREFERRED_LANGUAGE" COMMENT $$The patient's preferred language$$, 
  
    "LOW_LITERACY" COMMENT $$Whether the patient is tagged as low literacy$$, 
  
    "SMS_OPT_IN" COMMENT $$Whether the patient is opted in to SMS communication$$, 
  
    "LAST_PCP_APPT_DATE" COMMENT $$The patient's last PCP appointment date$$, 
  
    "LOCATION_NAME" COMMENT $$$$, 
  
    "GROUP_ID" COMMENT $$The group identifier for the reminder.  Groups are based on the department (specialty), the location (virtual, virtual-in-center, in person etc.) and the language (English, Spanish; Castilian etc.)$$, 
  
    "EVENT_ID" COMMENT $$The event identifier.$$, 
  
    "EVENT_NAME" COMMENT $$The event name.$$, 
  
    "EVENT_DELIVERY_METHOD" COMMENT $$The delivery method of the message.$$, 
  
    "MESSAGE_TEMPLATE_ID" COMMENT $$The messaging template identifier.$$, 
  
    "MESSAGE_TEMPLATE" COMMENT $$The messaging template used.$$
  
)

  copy grants
  
  
  as (
    

with low_literacy_patients as (
    select
        suvida_id,
        patient_id,
        tag_value
    from dw_dev.dev_jkizer.fct_patient_tag
    where
        tag_value in ('Low Literacy', 'Low-literacy') and
        is_active_tag = TRUE
),

-- Strictest interpretation: patient must have latest_is_consented = true for EVERY
-- messaging category they've answered. Any latest-per-category "no" excludes the patient.
-- Reads from dim_patient_consent (PR 6 refactor).
latest_text_consents as (
    select suvida_id
    from dw_dev.dev_jkizer.dim_patient_consent
    where category in (
        'SMS (Text) Communications',
        'Electronic Appointment Notifications',
        'Mobile Phone Communications',
        'Electronic Communications'
    )
    group by suvida_id
    having booland_agg(latest_is_consented) = true
)

select
    ps.suvida_id,
    ps.elation_id,
    ps.first_name,
    ps.last_name,
    ps.phone,
    ps.preferred_language,
    iff(llpt.tag_value is null, false, true) as low_literacy,
    iff(ptcs.suvida_id is null, false, true) as sms_opt_in,
    ps.last_pcp_appt_date,
    ps.location_name,
    grps.group_id,
    evnts.event_id,
    evnts.event_name,
    evnts.event_delivery_method,
    tmpl.template_id as message_template_id,
    tmpl.template as message_template
from dw_dev.dev_jkizer.patient_summary ps
left join low_literacy_patients llpt
    on ps.suvida_id = llpt.suvida_id and
        ps.elation_id = llpt.patient_id
left join latest_text_consents ptcs
    on ps.suvida_id = ptcs.suvida_id
left join source_prod.sms.patient_appointment_followup_reminders_groups grps
    on
        case
            when lower(ps.preferred_language) = 'spanish' then 'spanish; castilian'
            when ps.preferred_language is null or ps.preferred_language = '' then 'english'
            else lower(ps.preferred_language)
        end = lower(grps.language)
left join source_prod.sms.patient_appointment_followup_reminders_events evnts
    on grps.group_id = evnts.group_id and
       evnts.event_delay = datediff(day, to_date(ps.last_pcp_appt_date), to_date(sysdate()))
left join source_prod.sms.patient_appointment_followup_reminders_event_logs lgs
        on evnts.event_id = lgs.event_id and
           ps.suvida_id = lgs.suvida_id
left join source_prod.messaging.template tmpl
    on evnts.message_template = tmpl.template_id
-- Pull and match on any patients that have manually opted out via texting STOP (patient Id + delivery method)
left join source_prod.messaging.dncr dncr
    on ps.elation_id = dncr.elation_id and
        trim(lower(evnts.event_delivery_method)) = trim(lower(dncr.dncr_type))
where
    ps.is_active_assignment = 1 and
    lower(ps.elation_status) <> 'deceased' and
    ps.next_pcp_appt_date is null and
    (        
        datediff(day, to_date(ps.last_pcp_appt_date), to_date(sysdate())) = 10 or
        datediff(day, to_date(ps.last_pcp_appt_date), to_date(sysdate())) = 3 or
        to_date(sysdate()) = dateadd(month, 5, to_date(ps.last_pcp_appt_date)) or 
        to_date(sysdate()) = dateadd(week, 1, dateadd(month, 5, to_date(ps.last_pcp_appt_date)))
    ) and
    evnts.event_enabled = TRUE and
    lgs.event_id is null
  );

