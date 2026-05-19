----- TABLE ONLY USED FOR 2024 BONUS METRICS. DATES ARE HARDCODED TO 2024 

with denominator as (
	select
		ps.suvida_id
	from dw_dev.dev_jkizer.patient_summary ps
	left join dw_dev.dev_jkizer.patient_hcc_diagnosis phd
		on ps.suvida_id = phd.suvida_id
	where (phd.model = '24') and (ps.age_year > 65 or (phd.diabetes_cc_flag = 1 or phd.diabetes_non_cc_flag = 1)) -- careful adding conditions here not how this evaluates
), in_house_quantaflo as (
	select
		suvida_id,
		row_number() over (partition by suvida_id order by cpt_date desc) as _rn
	from dw_dev.dev_jkizer.fct_procedure fp
	where cpt_code in ('93922', '93923', '93924')
	and cpt_date >= dateadd(month, -24, '2024-12-31')-- Quantaflo & ABI
), quantaflo_reports as (
	select
		suvida_id,
		report_id,
		creation_datetime,
		signed_datetime,
		row_number() over (partition by suvida_id order by creation_datetime desc) as _rn
	from dw_dev.dev_jkizer.fct_elation_report fr
	where creation_datetime >= dateadd(month, -24, '2024-12-31') -- quantaflo report good for two years
	and is_quantaflo = 1
), pvd_patients as ( -- chf diagnosis satisfies screening
	select
		suvida_id
	from dw_dev.dev_jkizer.patient_hcc hd
	where hcc_label in ('Vascular Disease')
	and hcc_ind = 1
	and hcc_model = '24'
)
select
	2024 as measure_year,
	ps.suvida_id,
	ps.elation_id,
	ps.first_name,
	ps.last_name,
	ps.birth_date,
	ps.location_name,
	ps.provider_name,
	ps.num_pcp_visits_ytd_group,
	ps.next_pcp_appt_date,
	'chronic_disease_management' as measure_group,
	'pvd_screening' as measure_name,
	case
		when p.suvida_id is not null then 'Satisfied by PVD Diagnosis'
		when ihq.suvida_id is not null then 'Satisfied by Quantaflo'
		when qr.suvida_id is not null then 'Satisfied by Quantaflo Report'
		else 'Not Satisfied'
	end as measure_detail,
	case
		when p.suvida_id is not null then 1
		when ihq.suvida_id is not null then 1
		when qr.suvida_id is not null then 1
		else 0
	end as measure_numerator,
	1 as measure_denominator
from dw_dev.dev_jkizer.patient_summary ps
inner join denominator d
	on ps.suvida_id = d.suvida_id
left join in_house_quantaflo ihq
	on d.suvida_id = ihq.suvida_id
	and ihq._rn = 1
left join quantaflo_reports qr
	on d.suvida_id = qr.suvida_id
	and qr._rn = 1
left join pvd_patients p
	on d.suvida_id = p.suvida_id
where ps.is_active_patient = 1