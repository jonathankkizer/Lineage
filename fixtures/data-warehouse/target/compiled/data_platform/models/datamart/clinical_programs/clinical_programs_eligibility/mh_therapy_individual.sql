with time_period as ( -- create date spine so we can create rolling periods of time
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
), mh_p_dx as ( -- grab patients with specific diagnoses within specified rolling time period
	select
		tp.date_month_start,
		tp.date_month_end,
		fd.suvida_id,
		max(fd.diagnosis_date) || ' - ' || listagg(distinct fd.icd_10_code, ' | ') as eligibility_evidence
	from time_period tp 
	inner join dw_dev.dev_jkizer.fct_diagnosis fd
		on 1=1
	where diagnosis_date >= dateadd(month, -12, tp.date_month_start)
	and diagnosis_date <= tp.date_month_start
	and source_type = 'emr'
	and (icd_10_code ilike 'F32%' 
		or icd_10_code ilike 'F33%' 
		or icd_10_code ilike 'F411%' 
		or icd_10_code ilike 'F410%' 
		or icd_10_code ilike 'F4310%'	--added PTSD
	)
	and suvida_id is not null
	group by all
), mh_p_screener as ( -- grab patients with screener results above specified value
	select
		tp.date_month_start,
		tp.date_month_end,
		ph.suvida_id,
		history_type || ' - ' || history_value_numeric || ' - ' || date(ph.creation_datetime) as eligibility_evidence
	from time_period tp
	inner join dw_dev.dev_jkizer.fct_patient_history ph
		on 1=1
	where creation_datetime >= dateadd(month, -12, tp.date_month_start)
	and creation_datetime <= tp.date_month_start
	and history_type in ('GAD-7', 'PHQ-9')		-- allow any value
	and suvida_id is not null
	qualify row_number() over (partition by suvida_id, date_month_start order by creation_datetime desc, history_value_numeric desc) = 1
)
select
	date_month_start,
	date_month_end,
	suvida_id,
	array_to_string(array_construct_compact(s.eligibility_evidence, d.eligibility_evidence), ' | ') as eligibility_evidence,
	'mh' as team,
	'mh_t_individual' as program,
	'mh_therapy_individual' as eligibility_logic
from mh_p_dx d 
inner join mh_p_screener s 
	using (date_month_start, date_month_end, suvida_id)