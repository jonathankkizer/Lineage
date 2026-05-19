
  
    

create or replace transient table dw_dev.dev_jkizer.patient_visit_summary_month
    copy grants
    
    
    as (with enrollment_period as (
	select 
		suvida_id, 
		min(assignment_month) as first_date_month, 
		max(assignment_month) as last_date_month
	from dw_dev.dev_jkizer.fct_assignment_month pam
	where assignment_month_ind = 1
	and is_ops_month = true
	group by suvida_id
), suvida_months as (
	select 
		date_month as observation_month, 
		max(date_day) as end_of_observation_month
	from dw_dev.dev_jkizer.dim_date dd
	where dd.date_month between '2022-11-01' and current_date() 
	group by date_month
), member_observation_months as (
	select 
		suvida_id, 
		first_date_month,
		observation_month, 
		end_of_observation_month, 
		dateadd(day, 90, first_date_month) as ninety_days_from_enrollment,
		dateadd(day, 60, first_date_month) as sixty_days_from_enrollment
	from enrollment_period epd
	inner join suvida_months sms 
		on sms.observation_month >= epd.first_date_month  
		and sms.observation_month <= epd.last_date_month
), cte_cpt_mom as (
	select 
		mom.suvida_id,
		mom.first_date_month,
		mom.observation_month,
		mom.end_of_observation_month,
		mom.ninety_days_from_enrollment,
		cpt.encounter_date as cpt_date,
		cpt.is_awv,
		cpt.is_pcp as is_office_visit,
		cpt.is_tcm as is_tcm_visit,
		case when cpt.encounter_date <= ninety_days_from_enrollment then 1 else 0 end as ninety_days,
		case when cpt.encounter_date <= sixty_days_from_enrollment then 1 else 0 end as sixty_days,
		case when datediff(day, cpt.encounter_date, mom.end_of_observation_month) <= 90 then 1 else 0 end as is_visit_within_ninety_days
	from member_observation_months mom
	left join dw_dev.dev_jkizer.fct_procedure cpt 
		on cpt.suvida_id = mom.suvida_id 
		and cpt.encounter_date <= mom.end_of_observation_month
),
cte_agg_visits as (
	select 
		observation_month,
		suvida_id,
		max(case when is_office_visit = 1 and ninety_days = 1 then 1 else 0 end) as visit_in_90_days,
		max(case when is_awv = 1 and ninety_days = 1 then 1 else 0 end) as awv_in_90_days,
		max(case when is_office_visit = 1 and sixty_days = 1 then 1 else 0 end) as visit_in_60_days,
		max(case when is_awv = 1 and sixty_days = 1 then 1 else 0 end) as awv_in_60_days,
		max(CASE WHEN is_awv = 1 AND cpt_date >= DATEFROMPARTS(YEAR(observation_month), 1, 1) AND cpt_date <= LAST_DAY(observation_month) THEN 1 ELSE 0 END) as awv_completed,
		max(CASE WHEN is_office_visit = 1 AND cpt_date >= DATEFROMPARTS(YEAR(observation_month), 1, 1) AND cpt_date <= LAST_DAY(observation_month) THEN 1 ELSE 0 END) as visit_completed,
    	max(is_tcm_visit) as tcm_completed,
		max(case when (is_awv = 1 or is_office_visit = 1 or is_tcm_visit = 1) and is_visit_within_ninety_days = 1 then 1 else 0 end) as last_visit_within_90_days
	from cte_cpt_mom
	group by observation_month, 
	suvida_id
)
select
	cav.observation_month,
	cav.suvida_id,
	per.payer_name,
	per.payer_name as source,
	cav.visit_in_90_days,
	cav.awv_in_90_days,
	cav.visit_in_60_days,
	cav.awv_in_60_days,
	cav.awv_completed,
	cav.visit_completed,
	cav.tcm_completed,
	cav.last_visit_within_90_days,
	per.is_active_patient as engaged_status,
	per.provider_name,
	per.location_name
from cte_agg_visits cav
left join dw_dev.dev_jkizer.patient_summary per 
	on cav.suvida_id = per.suvida_id
    )
;


  