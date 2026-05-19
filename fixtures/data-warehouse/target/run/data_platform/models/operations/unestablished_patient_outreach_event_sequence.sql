
  create or replace   view dw_dev.dev_jkizer.unestablished_patient_outreach_event_sequence
  
  copy grants
  
  
  as (
    

with latest_patient_outreach_events as (
	select
		upor.suvida_id,
		upor.group_id,
		max(event_order) as max_event
	from dw_dev.dev_jkizer.unestablished_patient_outreach_roster upor
	left join source_prod.sms.patient_outreach_event_logs lgs
        on upor.suvida_id = lgs.suvida_id
	left join source_prod.sms.patient_outreach_group_events evnts
        on lgs.event_id = evnts.event_id
	group by
        upor.suvida_id,
        upor.group_id
),

latest_patient_outreach_event_ids as (
	select
		lpoe.suvida_id,
		lpoe.group_id,
		event_id,
		event_order,
		event_delay
	from latest_patient_outreach_events lpoe
	left join source_prod.sms.patient_outreach_group_events evnts
		on lpoe.group_id = evnts.group_id and 
		   lpoe.max_event = evnts.event_order
),

latest_patient_outreach_event_dates as (
	select
		lpoei.suvida_id,
		lpoei.group_id,
		lpoei.event_id,
		lpoei.event_order,
		lpoei.event_delay,
		lgs.created_date,
		row_number() over (partition by lpoei.suvida_id, lpoei.group_id, lpoei.event_id order by lgs.created_date asc) as _idx
	from latest_patient_outreach_event_ids lpoei
	left join source_prod.sms.patient_outreach_event_logs lgs
		on lpoei.suvida_id = lgs.suvida_id and
		   lpoei.group_id = lgs.group_id and
		   lpoei.event_id = lgs.event_id
),

next_patient_outreach_event_order as (
	select
		suvida_id,
		group_id,
		case
			when event_order is null then 1
			else event_order + 1
		end as next_event_sequence,
		created_date as last_sequence_date
	from latest_patient_outreach_event_dates
	where _idx = 1
),

next_patient_outreach_event as (
	select
		npoeo.suvida_id,
		npoeo.group_id,
		evnts.event_id,
		evnts.event_name,
		evnts.event_order,
		evnts.event_type,
		evnts.flow_id,
		last_sequence_date,
		dateadd(second, event_delay, last_sequence_date) as next_sequence_date,
		poem.message_id,
		poem.message_language,
		poem.message_body,
		poec.call_number
	from next_patient_outreach_event_order npoeo
	left join source_prod.sms.patient_outreach_group_events evnts 
        on npoeo.group_id = evnts.group_id and
           evnts.event_order = npoeo.next_event_sequence
	left join source_prod.sms.patient_outreach_event_messages poem
        on evnts.event_id = poem.event_id
	left join source_prod.sms.patient_outreach_event_calls poec
        on evnts.event_id = poec.event_id
)

select 
	pts.*,
	npoe.event_id,
	npoe.event_name,
	npoe.event_type,
	npoe.flow_id,
	npoe.next_sequence_date,
	npoe.last_sequence_date,
	npoe.message_id,
	npoe.message_language,
	npoe.message_body,
	npoe.call_number
from next_patient_outreach_event npoe
left join dw_dev.dev_jkizer.unestablished_patient_outreach_roster pts
    on npoe.suvida_id = pts.suvida_id
where
    pts.phone is not null and 
    (
        (message_language is null) or
    	(
    		preferred_language is not null and
    		lower(preferred_language) = lower(message_language)
    	) or
    	(
    		preferred_language is null and message_language = 'English'
    	)
    )
  );

