
  create or replace   view dw_dev.dev_jkizer.intmdt_patient_communication
  
  copy grants
  
  
  as (
    /*
    Purpose: Unified cross-platform patient communication record combining outbound Twilio messages, 
             Teams calls, TalkDesk calls, and inbound Carenet calls into a single consistent schema.
    Grain: One row per communication interaction per platform.
    Usage: Downstream source for patient_communication.
*/




with twilio as (
    select
        md5(cast(coalesce(cast(r.resource_sid as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(r.date_created as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_communication_skey,
        r.resource_sid as interaction_id,
        r.suvida_id,
        r.direction,
        r.destination as phone,
        r.source as from_number,
        null as talkdesk_phone_display_name,
        '(Automations)' as "user",
        null as duration_time_seconds,
        null as ring_time_seconds,
        null as wait_time_seconds,
        null as hold_time_seconds,
        r.resource_campaign::string as campaign,
        r.resource_context::string as context,
        null as disposition_code,
        null as disposition_set,
        null as nested_disposition,
        iff(r.resource_type = 'Voice', 'Call', r.resource_type) as delivery_method,
        'Twilio' as platform,
        r.date_created as "timestamp",
        rs.status,
        case
            when rs.status in ('delivered', 'sent', 'completed') then TRUE
            else FALSE
        end as is_completed,
        r.destination as patient_phone
    from dw_dev.dev_jkizer_staging.stg_messaging_resource r
    left join dw_dev.dev_jkizer_staging.stg_messaging_resource_status rs
        on r.resource_sid = rs.resource_sid
    where
        r.direction = 'Outbound'
    qualify row_number() over (partition by rs.resource_sid, r.resource_context:event_id order by rs.status_date desc) = 1
),

teams as (
    -- Note: suvida_id is null - Teams call records do not contain patient identifiers
    select
        md5(cast(coalesce(cast(cr.id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cr.invite_date_time as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_communication_skey,
        cr.id as interaction_id,
        null as suvida_id,
        iff(cr.is_inbound_call = TRUE, 'Inbound', 'Outbound') as direction,
        cr.callee_number_clean as phone,
        cr.caller_number_clean as from_number,
        null as talkdesk_phone_display_name,
        cr.user_display_name as "user",
        cr.duration_seconds as duration_time_seconds,
        timestampdiff('second', cr.invite_date_time, coalesce(cr.start_date_time, cr.failure_date_time)) as ring_time_seconds,
        null as wait_time_seconds,
        null as hold_time_seconds,
        null as campaign,
        null as context,
        null as disposition_code,
        null as disposition_set,
        null as nested_disposition,
        'Call' as delivery_method,
        'Teams' as platform,
        cr.invite_date_time as "timestamp",
        case
            when cr.successful_call = TRUE then 'completed'
            when cr.is_failed_call = TRUE then 'failed'
            when cr.is_missed_call = TRUE then 'missed'
            else null
        end as status,
        cr.successful_call as is_completed,
        iff(
            cr.is_outbound_call = TRUE,
            cr.callee_number_clean,
            cr.caller_number_clean
        ) as patient_phone
    from dw_dev.dev_jkizer_staging.stg_teams_call_record cr
    -- Teams source contains duplicate call records with identical data; deduplicate to one row per call
    qualify row_number() over (partition by cr.id order by cr.invite_date_time desc) = 1
),

talkdesk as (
    -- Note: suvida_id is null - TalkDesk call records do not contain patient identifiers
    select
        md5(cast(coalesce(cast(c.callsid as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(c.start_at as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_communication_skey,
        c.callsid as interaction_id,
        null as suvida_id,
        case
            when c.type = 'abandoned' then 'Inbound'
            when c.type = 'inbound' then 'Inbound'
            when c.type = 'missed' then 'Inbound'
            when c.type = 'outbound' then 'Outbound'
            when c.type = 'outbound_missed' then 'Outbound'
            when c.type = 'short_abandoned' then 'Inbound'
            when c.type = 'voicemail' then 'Inbound'
            else c.type
        end as direction,
        c.contact_phone_number as phone,
        c.talkdesk_phone_number as from_number,
        talkdesk_phone_display_name,
        c.user_name as "user",
        c.total_time as duration_time_seconds,
        c.total_ringing_time as ring_time_seconds,
        c.wait_time as wait_time_seconds,
        c.hold_time as hold_time_seconds,
        null as campaign,
        null as context,
        disposition_code,
        null as disposition_set, 
        null as nested_disposition,
        'Call' as delivery_method,
        'TalkDesk' as platform,
        to_timestamp_ntz(c.start_at) as "timestamp",
        null as status,
        null as is_completed,
        c.contact_phone_number as patient_phone
    from dw_dev.dev_jkizer.intmdt_talkdesk_call c
),

carenet as (
    select
        md5(cast(coalesce(cast(cn.transaction_number as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cn.service_date_opened as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_communication_skey,
        cn.transaction_number as interaction_id,
        cn.external_id as suvida_id,
        initcap(lower(contact_method)) as direction,
        cn.service_number as phone,
        cn.patient_phone as from_number,
        null as talkdesk_phone_display_name,
        coalesce(cn.user_fname, ' ', cn.user_lname) as "user",
        timestampdiff('second', cn.transaction_start_time, cn.transaction_end_time) as duration_time_seconds,
        null as ring_time_seconds,
        null as wait_time_seconds,
        null as hold_time_seconds,
        null as campaign,
        cn.services_provided as context,
        null as disposition_code,
        null as disposition_set,
        null as nested_disposition,
        'Call' as delivery_method,
        'Carenet' as platform,
        cn.transaction_start_time as "timestamp",
        cn.trx_status as status,
        TRUE as is_completed,
        cn.patient_phone as patient_phone
    from dw_dev.dev_jkizer_staging.stg_carenet_daily_extract cn
    where contact_method = 'INBOUND'
)

select * from twilio
union all
select * from teams
union all
select * from talkdesk
union all
select * from carenet
  );

