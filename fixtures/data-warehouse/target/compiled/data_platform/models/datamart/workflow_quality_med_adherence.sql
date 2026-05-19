with activity_source as (
	select
		airtable_id,
		last_modified_datetime,
		date(last_modified_datetime) as modified_date,
		ms_notes,
		action_plan_for_2026,
		next_follow_up_date,
		lower(last_modified_by_email) as last_modified_by_email,
		created_datetime,
		run_datetime
	from dw_dev.dev_jkizer_staging.stg_airtable_med_adherence
	qualify row_number() over (
		partition by
			airtable_id,
			last_modified_datetime,
			coalesce(ms_notes, '__NULL__'),
			coalesce(action_plan_for_2026, '__NULL__'),
			coalesce(to_varchar(next_follow_up_date), '__NULL__'),
			coalesce(lower(last_modified_by_email), '__NULL__')
		order by
			run_datetime desc nulls last,
			created_datetime desc nulls last
	) = 1
),

activity_changes as (
	select
		airtable_id,
		last_modified_datetime,
		modified_date,
		ms_notes,
		action_plan_for_2026,
		next_follow_up_date,
		last_modified_by_email,
		row_number() over (
			partition by airtable_id
			order by
				last_modified_datetime,
				created_datetime,
				run_datetime,
				coalesce(ms_notes, ''),
				coalesce(action_plan_for_2026, ''),
				coalesce(to_varchar(next_follow_up_date), '')
		) as event_seq,
		case
			when ms_notes is distinct from lag(ms_notes) over (
				partition by airtable_id
				order by
					last_modified_datetime,
					created_datetime,
					run_datetime,
					coalesce(ms_notes, ''),
					coalesce(action_plan_for_2026, ''),
					coalesce(to_varchar(next_follow_up_date), '')
			)
			then 1 else 0
		end as ms_notes_changed,
		case
			when action_plan_for_2026 is distinct from lag(action_plan_for_2026) over (
				partition by airtable_id
				order by
					last_modified_datetime,
					created_datetime,
					run_datetime,
					coalesce(ms_notes, ''),
					coalesce(action_plan_for_2026, ''),
					coalesce(to_varchar(next_follow_up_date), '')
			)
			then 1 else 0
		end as action_plan_for_2026_changed,
		case
			when next_follow_up_date is distinct from lag(next_follow_up_date) over (
				partition by airtable_id
				order by
					last_modified_datetime,
					created_datetime,
					run_datetime,
					coalesce(ms_notes, ''),
					coalesce(action_plan_for_2026, ''),
					coalesce(to_varchar(next_follow_up_date), '')
			)
			then 1 else 0
		end as next_follow_up_date_changed
	from activity_source
),

activity_flags as (
	select
		airtable_id,
		last_modified_datetime,
		ms_notes,
		action_plan_for_2026,
		next_follow_up_date,
		last_modified_by_email,
		case
			when last_modified_by_email in ('jkizer@suvidahealthcare.com', 'automations@noreply.airtable.com')
				then false
			when min(case when ms_notes_changed = 1 then event_seq end) over (partition by airtable_id, modified_date) is not null
				and min(case when next_follow_up_date_changed = 1 then event_seq end) over (partition by airtable_id, modified_date) is not null
				and event_seq = greatest(
					min(case when ms_notes_changed = 1 then event_seq end) over (partition by airtable_id, modified_date),
					min(case when next_follow_up_date_changed = 1 then event_seq end) over (partition by airtable_id, modified_date)
				)
				then true
			else false
		end as is_activity_flag,
		case
			when last_modified_by_email in ('jkizer@suvidahealthcare.com', 'automations@noreply.airtable.com')
				then false
			when min(case when action_plan_for_2026_changed = 1 then event_seq end) over (partition by airtable_id, modified_date) is not null
				and min(case when next_follow_up_date_changed = 1 then event_seq end) over (partition by airtable_id, modified_date) is not null
				and event_seq = greatest(
					min(case when action_plan_for_2026_changed = 1 then event_seq end) over (partition by airtable_id, modified_date),
					min(case when next_follow_up_date_changed = 1 then event_seq end) over (partition by airtable_id, modified_date)
				)
				then true
			else false
		end as is_action_plan_activity_flag
	from activity_changes
),

stage_1_stage_6_cycle_time as (
	select
		med_adherence_measure_skey,
		max(iff(stage_med_adh_outreach like 'Stage 1%', last_modified_datetime, null)) as recent_stage_1_datetime,
		max(iff(stage_med_adh_outreach like 'Stage 6%', last_modified_datetime, null)) as recent_stage_6_datetime,
		datediff(
			day,
			max(iff(stage_med_adh_outreach like 'Stage 1%', last_modified_datetime, null)),
			max(iff(stage_med_adh_outreach like 'Stage 6%', last_modified_datetime, null))
		) as days_stage_1_stage_6
	from dw_dev.dev_jkizer_staging.stg_airtable_med_adherence
	group by med_adherence_measure_skey
)

select
	fqm.suvida_id,
	fqm.quality_measure,
	fqm.measure_source,
	fqm.measure_year,
	fqm.real_time_gdr,
	apc.med_adherence_measure_skey,
	apc.airtable_id,
	apc.ms_action,
	apc.opportunity,
	apc.barriers,
	apc.interventions,
	apc.ms_notes,
	apc.action_plan_for_2026,
	apc.elation_note,
	apc.next_follow_up_date,
	apc.stage_med_adh_outreach,
	apc.personal_notes,
	apc.medication_specialist,
	apc.cost_barrier_lis_addressed,
	apc.ds_90_100_day_addressed,
	apc.transportation_addressed,
	apc.pcp_action_addressed,
	apc.center_support_addressed,
	apc.pharmacy_issue_addressed,
	apc.last_modified_by_name,
	apc.last_modified_by_email,
	apc.last_modified_datetime,
	apc.is_automated_activity,
	apc.workflow_status_index,
	cycletime.recent_stage_1_datetime,
	cycletime.recent_stage_6_datetime,
	iff(cycletime.recent_stage_6_datetime >= cycletime.recent_stage_1_datetime, cycletime.days_stage_1_stage_6, null) as days_stage_1_stage_6,
	coalesce(activity_flags.is_activity_flag, false) as is_activity_flag,
	coalesce(activity_flags.is_action_plan_activity_flag, false) as is_action_plan_activity_flag
from dw_dev.dev_jkizer_staging.stg_airtable_med_adherence apc
inner join dw_dev.dev_jkizer.fct_med_adherence fqm
	on apc.med_adherence_measure_skey = fqm.med_adherence_measure_skey
	and fqm.med_adherence_report_rank = 1
left join stage_1_stage_6_cycle_time cycletime
	on apc.med_adherence_measure_skey = cycletime.med_adherence_measure_skey
left join activity_flags
	on apc.airtable_id = activity_flags.airtable_id
	and apc.last_modified_datetime = activity_flags.last_modified_datetime
	and apc.ms_notes is not distinct from activity_flags.ms_notes
	and apc.action_plan_for_2026 is not distinct from activity_flags.action_plan_for_2026
	and apc.next_follow_up_date is not distinct from activity_flags.next_follow_up_date
	and lower(apc.last_modified_by_email) is not distinct from activity_flags.last_modified_by_email