with time_period as (
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end,
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
), chf_stage_c_d as (
	select
		siw.suvida_id,
		im.imo_description,
		min(pp.start_date) as start_date,
		greatest_ignore_nulls(max(pp.resolved_date), max(pp.deletion_datetime), '2099-12-31') as end_date,
	from dw_dev.dev_jkizer_staging.stg_elation_patient_problem pp
	inner join dw_dev.dev_jkizer_staging.stg_elation_patient_problem_code ppc
		on pp.patient_problem_id = ppc.patient_problem_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_imo im
		on ppc.imo_code = im.imo_code
	inner join dw_dev.dev_jkizer_staging.stg_elation_icd10 ic
		on ppc.icd10 = ic.icd10_id
		and im.uq_id = ic.imo_id
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on pp.patient_id = siw.member_id
		and siw.source = 'Elation'
	where im.imo_description ilike '%chf%' and (im.imo_description ilike '%stage c%' or im.imo_description ilike '%stage d%')
	group by all
)
select
	tp.date_month_start,
	tp.date_month_end,
	c.suvida_id,
	c.imo_description as eligibility_evidence,
	'pharmd' as team,
	'chf' as program,
	'pharmd_chf' as eligibility_logic,
from time_period tp
inner join chf_stage_c_d c 
	on 1=1
where tp.date_month_start >= c.start_date and tp.date_month_start <= end_date