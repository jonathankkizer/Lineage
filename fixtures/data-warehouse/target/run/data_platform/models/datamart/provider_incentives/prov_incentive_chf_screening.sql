
  
    

create or replace transient table dw_dev.dev_jkizer.prov_incentive_chf_screening
    copy grants
    
    
    as (----- TABLE ONLY USED FOR 2024 BONUS METRICS. DATES ARE HARDCODED TO 2024 

with dx_factors as ( -- diagnoses factors considered risks for CHF
	select 
		suvida_id,
		max(case when replace(icd_10_code, '.','') in ('E6601','E662','Z6841','Z6842','Z6843','Z6844','Z6845') then 1 else 0 end) -- obesity dx
		+
		max(case when replace(icd_10_code, '.', '') in ('I480','I4811','I4819','I4820','I4821','I4891') then 1 else 0 end) -- afib dx
		+
		max(case when replace(icd_10_code, '.', '') in ('I10','I150','I151','I152','I158','I159','I270','I2720','I2721','I2722','I2723','I2724','I2729','I87311','I87312','I87313','I87319','I87331','I87332','I87333','I87339','K766') then 1 else 0 end) -- htn dx
		as num_risk_factors
	from dw_dev.dev_jkizer.fct_diagnosis
	where source_type = 'emr' and
	diagnosis_date >= dateadd(week, -54, '2024-12-31')
	group by suvida_id
), hcc_factors as ( -- hcc factors considered risks for CHF
	select
		suvida_id,
		count(hcc_label) as num_risk_factors
	from dw_dev.dev_jkizer.patient_hcc
	where hcc_label in ('Vascular Disease', 'Diabetes with Chronic Complications', 'Diabetes without Complication')
	and hcc_ind = 1
	and hcc_model = '24'
	group by suvida_id
), chf_patients as ( -- chf diagnosis satisfies screening
	select
		suvida_id
	from dw_dev.dev_jkizer.patient_hcc hd
	where hcc_label in ('Congestive Heart Failure')
	and hcc_ind = 1
	and hcc_model = '24'
), echo_reports as (
	select 
		suvida_id,
		report_id,
		creation_datetime,
		signed_datetime,
		row_number() over (partition by suvida_id order by creation_datetime desc) as _rn
	from dw_dev.dev_jkizer.fct_elation_report fr 
	where creation_datetime >= dateadd(month, -24, '2024-12-31') -- echo report good for two years
	and is_echo = 1
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
	'echo_screening' as measure_name,
	case 
		when chf.suvida_id is not null then 'Satisfied by CHF diagnosis' 
		when er.suvida_id is not null then 'Satisfied by Echo report'
		else 'Not satisfied'
	end as measure_detail,
	case
		when chf.suvida_id is not null then 1 -- satisfied by CHF diagnosis
		when er.suvida_id is not null then 1  -- satisfied by echo report
		else 0
	end as measure_numerator,
	1 as measure_denominator
from dw_dev.dev_jkizer.patient_summary ps
left join dx_factors dx
	on ps.suvida_id = dx.suvida_id
left join hcc_factors hf
	on ps.suvida_id = hf.suvida_id
left join chf_patients chf
	on ps.suvida_id = chf.suvida_id
left join echo_reports er 
	on ps.suvida_id = er.suvida_id
	and er._rn = 1
where ps.age_year > 65
and (coalesce(dx.num_risk_factors, 0) + coalesce(hf.num_risk_factors, 0)) >= 1
and ps.is_active_patient = 1
    )
;


  