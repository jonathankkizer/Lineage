
  
    

create or replace transient table dw_dev.dev_jkizer.fct_visit_note_timing
    copy grants
    
    
    as (with bullet_data as ( -- generate array of the most recent eligibility files received in each month
	select 
		visit_note_id,
		visit_note_bullet_id,
		last_modified_datetime,
	from dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet
	where deleted_datetime is null
), groupings as ( -- rank and get the most recent previous report for each member
	select 
		dense_rank() over (partition by visit_note_id order by last_modified_datetime) as rn,
		visit_note_id,
		visit_note_bullet_id,
		last_modified_datetime,
		lag(last_modified_datetime, 1) over (partition by visit_note_id order by last_modified_datetime asc) as prev_last_modified
	from bullet_data
), island_id as ( -- flag if the max time delta is greater than 3 minutes
	select
		*,
		case when timestampdiff(minute, prev_last_modified, last_modified_datetime) <= 3 then 0 else 1 end as island_start_ind,
		sum(case when timestampdiff(minute, prev_last_modified, last_modified_datetime) <= 3 then 0 else 1 end) over (partition by visit_note_id order by rn) as island_id
	from groupings
), island_timings as (
	select 
		visit_note_id, 
		island_id, 
		min(last_modified_datetime) as island_first_action_datetime, 
		max(last_modified_datetime) as island_last_action_datetime, 
		timestampdiff(minute, min(last_modified_datetime), max(last_modified_datetime)) as time_minutes, 
		count(*) as action_count,
	from island_id
	--where visit_note_id = '931879262289944'
	group by all
)
select 
	visit_note_id, 
	sum(time_minutes) as inferred_time_minutes,
	sum(action_count) as action_count,
from island_timings 
group by visit_note_id
    )
;


  