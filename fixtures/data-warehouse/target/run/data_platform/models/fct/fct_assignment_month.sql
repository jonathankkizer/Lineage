
  
    

create or replace transient table dw_dev.dev_jkizer.fct_assignment_month
    copy grants
    
    
    as (with monthly_files as ( -- generate array of the most recent eligibility files received in each month
	select 
		member_id,
		member_file_skey,
		src_file_name, 
		report_date,
		source,
		coalesce(lob_file, source_lob) as source_lob, --if united enrollment file, take the lob_file instead of source_lob
		suvida_start_date,
		date_trunc(month, report_date) as report_month
	from dw_dev.dev_jkizer.intmdt_assignment
), groupings as ( -- rank and get the most recent previous report for each member
	select 
		dense_rank() over (partition by member_id order by report_date) as rn,
		member_id,
		member_file_skey,
		report_date,
		report_month,
		suvida_start_date,
		source,
		source_lob,
		src_file_name,
		lag(report_month, 1) over (partition by member_id order by report_date) as _prev_report_month
	from monthly_files
), island_id as ( -- flag if the max time delta between current record's month and previous is <= 1 month
	select
		*,
		case when datediff(month, _prev_report_month, report_month) <= 1 then 0 else 1 end as island_start_ind,
		sum(case when datediff(month, _prev_report_month, report_month) <= 1 then 0 else 1 end) over (partition by member_id order by rn) as island_id
	from groupings
), membership_episode_data as (
	select 
		member_id,
		member_file_skey,
		report_date,
		report_month as payer_report_month,
		iff(report_month >= suvida_start_date, report_month, suvida_start_date) as report_month, -- handles future start case
		source,
		source_lob,
		src_file_name,
		_prev_report_month,
		island_start_ind,
		island_id,
		iff(min(report_month) over (partition by member_id) = report_month, true, false) as is_earliest_report_month,
		iff(report_month >= min(report_month) over (partition by member_id), true, false) as is_ops_month
	from island_id
), membership_episode_start_data as ( -- process starts of assignment episodes by generating array of dates between suvida_start_date and report_month
	select 
		med.member_id,
		med.member_file_skey,
		med.source,
		med.source_lob,
		mf.suvida_start_date,
		med.payer_report_month,
		med.report_month,
		dd.date_day as assignment_month,
		1 as assignment_month_ind,
		island_id as eligibility_episode_id,
		iff(dd.date_day >= med.report_month, true, false) as is_ops_month
	from membership_episode_data med
	inner join monthly_files mf
		on med.member_id = mf.member_id
		and med.src_file_name = mf.src_file_name
		and med.report_date = mf.report_date
	inner join dw_dev.dev_jkizer.dim_date dd 
		on dd.date_day between mf.suvida_start_date and med.report_month
		and dd.is_bom = 1
	where island_start_ind = 1
	and dd.date_day >= '2022-11-01' -- first month of Suvida
), membership_episode_continue_data as ( -- handle all other months, checking for presence in each month
	select
		med.member_id,
		med.member_file_skey,
		med.source,
		med.source_lob,
		med.payer_report_month,
		med.report_month as assignment_month,
		1 as assignment_month_ind,
		island_id as eligibility_episode_id,
		med.is_ops_month
	from membership_episode_data med
	left join membership_episode_start_data mesd 
		on med.member_id = mesd.member_id
		and med.report_month = mesd.assignment_month
	where island_start_ind = 0
	and mesd.member_id is null
), combined_data as (
	select 
		member_id,
		member_file_skey,
		source,
		source_lob,
		payer_report_month,
		assignment_month,
		eligibility_episode_id,
		max(assignment_month_ind) as assignment_month_ind,
		max(is_ops_month) as is_ops_month,
	from membership_episode_start_data
	group by all
	union 
	select
		member_id,
		member_file_skey,
		source,
		source_lob,
		payer_report_month,
		assignment_month,
		eligibility_episode_id,
		max(assignment_month_ind) as assignment_month_ind,
		max(is_ops_month) as is_ops_month,
	from membership_episode_continue_data
	group by all
), max_data as (
	select
		source,
		source_lob,
		max(payer_report_month) as max_assignment_month
	from combined_data cd
	group by all
), carry_forward_data as (
	select 
		cd.member_id,
		cd.member_file_skey,
		cd.source,
		cd.source_lob,
		cd.payer_report_month,
		dd.date_day as assignment_month,
		cd.eligibility_episode_id,
		cd.assignment_month_ind,
		cd.is_ops_month,
	from combined_data cd
	inner join max_data md 
		on cd.source = md.source
		and coalesce(cd.source_lob, 'n/a') = coalesce(md.source_lob, 'n/a')
		and cd.assignment_month = md.max_assignment_month
	inner join dw_dev.dev_jkizer.dim_date dd 
		on dd.date_day > cd.assignment_month 
		and dd.date_day <= date_trunc(month, current_date())
		and dd.is_bom = 1
	where cd.assignment_month != date_trunc(month, current_date())
), membership_dataset as (
	select *
	from carry_forward_data
	union all 
	select *
	from combined_data
)
select 
	siw.suvida_id,
	md5(cast(coalesce(cast(md.member_file_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(md.assignment_month as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_month_skey,
	md.*,
	iff(assignment_month = date_trunc(month, current_date()), true, false) as is_current_month,
	iff(assignment_month > date_trunc(month, current_date()), true, false) as is_future_month,
from membership_dataset md
left join dw_dev.dev_jkizer.suvida_id_walk siw
	using (member_id, source)
    )
;


  