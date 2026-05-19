

with latest_patient_outreach_events as (
	select
		lgs.suvida_id,
		lgs.group_id,
		max(event_order) as max_event
	from source_prod.sms.patient_outreach_event_logs lgs
	left join source_prod.sms.patient_outreach_group_events evnts
        on lgs.event_id = evnts.event_id
    left join source_prod.sms.patient_outreach_groups  groups
        on lgs.group_id = groups.group_id
    where groups.active = TRUE
	group by
        lgs.suvida_id,
        lgs.group_id
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
),

aggregated_roster as (
    select
    	ps.suvida_id,
    	ps.elation_id,
    	ps.first_name,
    	ps.last_name,
    	case
    		when lower(ps.preferred_language) = 'spanish; castilian' then 'spanish'
    		else lower(ps.preferred_language)
    	end as preferred_language,
    	ps.phone,
    	is_active_enrollment,
		is_active_assignment,
    	is_active_patient,
    	next_pcp_appt_date,
    	eligibility_start_month,
        fpl.location_id,
    	'21F8D7AA-B8FB-4539-A9CD-3C7E1B058D6F' as group_id
    from dw_dev.dev_jkizer.patient_summary ps
    left join dw_dev.dev_jkizer.fct_patient_location fpl
        on ps.suvida_id = fpl.suvida_id
    left join dw_dev.dev_jkizer_staging.stg_elation_patient ept
        on ps.elation_id = ept.elation_id
    where
    	ps.is_active_assignment = 1 and
    	ps.first_pcp_appt_date is null and 
        ps.elation_id is not null and
    	ps.next_pcp_appt_date is null and
        datediff(hour, ept._creation_datetime, current_timestamp()) between 0 and 180
    
    union all
    
    select 
    	npoe.suvida_id,
        ps.elation_id,
        ps.first_name,
        ps.last_name,    
    	case
    		when lower(ps.preferred_language) = 'spanish; castilian' then 'spanish'
    		else lower(ps.preferred_language)
    	end as preferred_language,
    	ps.phone,
    	is_active_enrollment,
		is_active_assignment,
    	is_active_patient,
    	next_pcp_appt_date,
    	eligibility_start_month,    
        fpl.location_id,
        npoe.group_id
    from next_patient_outreach_event npoe
    left join dw_dev.dev_jkizer.patient_summary ps
        on npoe.suvida_id = ps.suvida_id
    left join dw_dev.dev_jkizer.fct_patient_location fpl
        on ps.suvida_id = fpl.suvida_id
    left join dw_dev.dev_jkizer_staging.stg_elation_patient ept
        on ps.elation_id = ept.elation_id
    where
    	npoe.event_id is not null and
        ps.next_pcp_appt_date is null and
        npoe.next_sequence_date <= current_date() and
        datediff(hour, ept._creation_datetime, current_timestamp()) between 0 and 180
    )

    select distinct *
    from aggregated_roster