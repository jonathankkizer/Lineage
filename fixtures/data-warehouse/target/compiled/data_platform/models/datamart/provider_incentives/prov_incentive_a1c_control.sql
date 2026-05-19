with dm_payer_patients as ( -- grab denominator of patients and current payer status from quality gap files
	select
		suvida_id,
		year(measure_year) as measure_year,
		greatest_ignore_nulls(measure_numerator, suvida_numerator) as measure_numerator,
		1 as measure_denominator,
		report_date,
		-- cpt_date,
		evidence_desc as cpt_codes,
	from dw_dev.dev_jkizer.patient_quality_measure
	where quality_measure = 'Diabetes Care - Blood Sugar Controlled'
	and is_measure_year_current_report = true
	qualify row_number() over (partition by suvida_id, year(measure_year) order by report_date desc) = 1
)

select
	dm.measure_year,
	ps.suvida_id,
	ps.elation_id,
	ps.first_name,
	ps.last_name,
	ps.birth_date,
	ps.location_name,
	ps.provider_name,
	ps.num_pcp_visits_ytd_group,
	ps.next_pcp_appt_date,
	'star_measures' as measure_group,
	'a1c_control' as measure_name,
	concat(
		'Code: ', cpt_codes, ' ', 
		/*'Code Date: ', to_varchar(dm.cpt_date), ' | ',*/
		'Payer Status: ', to_varchar(measure_numerator), ' ',
		'Payer Date: ', to_varchar(report_date)
	) as measure_detail,
	measure_numerator,
	1 as measure_denominator
from dw_dev.dev_jkizer.patient_summary ps
inner join dm_payer_patients dm
	on ps.suvida_id = dm.suvida_id
where ps.is_active_patient = 1