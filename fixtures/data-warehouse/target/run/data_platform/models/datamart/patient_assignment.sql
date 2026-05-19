
  
    

create or replace transient table dw_dev.dev_jkizer.patient_assignment
    copy grants
    
    
    as (with patient_min_max_month as (
	select
		fam.suvida_id,
		min(fam.assignment_month) as first_assignment_month,
		max(fam.assignment_month) as max_assignment_month,
		min(fam.assignment_month) as first_month,
		max(fam.assignment_month) as max_month,
	from dw_dev.dev_jkizer.fct_assignment_month fam
	group by 1
), elig_data as (
	select
		md5(cast(coalesce(cast(pmmm.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dd.date_month as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_assignment_skey,
		pmmm.suvida_id,
		dd.date_month,
		monthname(dd.date_month) as month_name,
		fam.source as assignment_source,
		dep.member_id as assignment_member_id,
		dep.medicare_beneficiary_id as assignment_medicare_beneficiary_id,
		dep.report_date,
		dep.payer_parent as assignment_payer_parent,
		dep.payer_name as assignment_payer_name,
		dep.payer_contract as assignment_payer_contract,
		dp_asg.provider_name as assignment_provider_name,
		dp_asg.location_name as assignment_location_name,
		max(case when fam.assignment_month is not null then 1 else 0 end) as assignment_month_ind,
		max(coalesce(case 
					when (dep.plan_name like '%Austin%' and dep.source = 'Devoted') or fam.assignment_month is null 
					then false
					else true end, false)) 
		as is_at_risk,
		dep.src_file_name as assignment_src_file_name,
		dep.source_lob,
		case 
			when dep.payer_name = 'Wellcare/Centene' then 'Wellcare'
			when dep.payer_name  = 'UHG/Wellmed' then concat('Wellmed', ' ', dep.source_lob)
			else concat(dep.payer_name , ' ', dep.source_lob)
		end as display_lob,
		dep.plan_name,
		dep.plan_network_type,
		dep.plan_program_type,
		dep.plan_network_program_type,
	from patient_min_max_month pmmm
	inner join dw_dev.dev_jkizer.dim_date dd 
		on dd.date_month between pmmm.first_month and current_date()
	left join dw_dev.dev_jkizer.fct_assignment_month fam 
		on pmmm.suvida_id = fam.suvida_id
		and dd.date_month = fam.assignment_month
	left join dw_dev.dev_jkizer.dim_assignment_patient dep
		on fam.member_file_skey = dep.member_file_skey
	left join dw_dev.dev_jkizer.dim_provider dp_asg
		on dep.pcp_npi = dp_asg.npi
	where dd.is_bom = 1
	group by all
	qualify row_number() over (partition by pmmm.suvida_id, dd.date_month order by dep.report_date desc) = 1 -- guarantees one record per patient per month, using the latest record for each month
), lag_inds as (
	select
		* exclude (report_date),
		coalesce(lag(assignment_month_ind) over (partition by suvida_id order by date_month asc), 0) as prev_month_assignment_ind,
		coalesce(lag(assignment_month_ind, 3) over (partition by suvida_id order by date_month asc), 0) as prev_3_month_assignment_ind,
		coalesce(lag(assignment_payer_name) over (partition by suvida_id order by date_month asc), 'None') as prev_month_assignment_payer_name,
	from elig_data
), pcp_visits as (
	select
		suvida_id,
		encounter_date as pcp_date
	from dw_dev.dev_jkizer.fct_procedure
	where is_pcp = 1
),
other_visits as (
	select
		suvida_id,
		encounter_date as other_visit_date
	from dw_dev.dev_jkizer.fct_procedure
	where is_rd = 1
		or is_ultrasound = 1
		or is_xray = 1
		or is_mh = 1
		or is_pt = 1
		or is_pharmacy = 1
		or is_guia = 1
		or is_rn = 1
),
assignment_bucket as (
select
	lag_inds.*,
	max(pcp_visits.pcp_date) as last_pcp_date,
	max(iff(datediff('day', pcp_visits.pcp_date, last_day(date_month)) <= 90, 1, 0)) as is_pcp_complete_last90d,
	max(other_visits.other_visit_date) as last_other_visit_date,
	max(iff(datediff('day', other_visits.other_visit_date, last_day(date_month)) <= 90, 1, 0)) as is_other_visit_complete_last90d,
	case when prev_month_assignment_payer_name != assignment_payer_name and prev_month_assignment_payer_name != 'None' then true else false
	end as is_payer_switch,
	case
		when assignment_month_ind = 1 and prev_month_assignment_ind = 0 and prev_3_month_assignment_ind = 0 then 'new'
		when assignment_month_ind = 1 and prev_month_assignment_ind = 0 and prev_3_month_assignment_ind = 1 then 'resume'
		when assignment_month_ind = 1 and prev_month_assignment_ind = 1 then 'active'
		when assignment_month_ind = 1 and prev_month_assignment_ind = 0 then 'new'
		when assignment_month_ind = 0 and prev_month_assignment_ind = 1 then 'lost'
		when assignment_month_ind = 0 and prev_month_assignment_ind = 0 then 'no_assignment'
	end as assignment_bucket,
from lag_inds
left join pcp_visits
	on pcp_visits.suvida_id = lag_inds.suvida_id
	and date_trunc('month', pcp_visits.pcp_date) <= lag_inds.date_month
left join other_visits
	on other_visits.suvida_id = lag_inds.suvida_id
	and date_trunc('month', other_visits.other_visit_date) <= lag_inds.date_month
group by all
)
select 
	*,
	iff(assignment_bucket = 'resume' or prev_month_assignment_ind = 1,1,0) as assignment_churn_denominator_ind,
	case 
		when month(date_month) in (1,2,3) then year(date_month) || 'Q1'
		when month(date_month) in (4,5,6) then year(date_month) || 'Q2'
		when month(date_month) in (7,8,9) then year(date_month) || 'Q3'
		when month(date_month) in (10,11,12) then year(date_month) || 'Q4'
	end as assignment_month_quarter,
from assignment_bucket
    )
;


  