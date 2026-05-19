/* for general approach, look into "gaps and groupings problem" */
/* https://bertwagner.com/posts/gaps-and-groupings/ */
with data as ( -- get relevant data and start/stops; if discharge_date isn't available, use admit_date and assume 1-day admission
	select 
		suvida_id, 
		admit_date, 
		coalesce(discharge_date, admit_date) as admit_end_date
	from dw_dev.dev_jkizer.intmdt_census_event
	where admit_date is not null
	and suvida_id is not null 
	and level_of_care in ('inpatient', 'emergency')
	and admission_order_desc = 1
), groupings as ( -- iterate over dataset, grabbing previous admit_end_date for each record group
	select 
		dense_rank() over (partition by suvida_id order by admit_date, admit_end_date) as rn,
		suvida_id,
		admit_date,
		admit_end_date,
		lag(admit_end_date, 1) over (partition by suvida_id order by admit_date, admit_end_date) as previous_admit_end_date
	from data
), census_grouping_id as ( -- check if that previous_admit_end_date is +1 or fewer days before current record's admit date (note that this means we identify records that end 1 day after our current admit_date as part of the same group)
	select
		*,
		case when datediff(day, previous_admit_end_date, admit_date) <= 30 then 0 else 1 end as grouping_start_ind,
		sum(case when datediff(day, previous_admit_end_date, admit_date) <= 30 then 0 else 1 end) over (partition by suvida_id order by rn) as census_grouping_id
	from groupings
), data_2 as ( -- begin process again, using output of previous grouping groupings; necessary because we can't guarantee our admit_end_date is temporally ordered with the first pass
	select 
		suvida_id, 
		census_grouping_id, 
		min(admit_date) as admit_date, 
		max(admit_end_date) as admit_end_date
	from census_grouping_id
	group by 1,2
), groupings_2 as ( -- same logic as above
	select 
		dense_rank() over (partition by suvida_id order by admit_date, admit_end_date) as rn,
		suvida_id,
		admit_date,
		admit_end_date,
		lag(admit_end_date, 1) over (partition by suvida_id order by admit_date, admit_end_date) as previous_admit_end_date
	from data_2
), census_grouping_id_2 as ( -- same logic as above
	select
		suvida_id,
		admit_date as admit_grouping_start_date,
		admit_end_date as admit_grouping_end_date,
		case when 
			datediff(day, previous_admit_end_date, admit_date) <= 30 
			then 0 
			else 1 
		end as grouping_start_ind,
		sum(case when 
			datediff(day, previous_admit_end_date, admit_date) <= 30
				then 0
				else 1 
			end) over (partition by suvida_id order by rn) as census_grouping_id
	from groupings_2
)
select 
	* exclude (census_grouping_id),
	md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_grouping_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as census_quality_grouping_id,
from census_grouping_id_2