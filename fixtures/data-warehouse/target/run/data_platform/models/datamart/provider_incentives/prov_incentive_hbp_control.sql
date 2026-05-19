
  
    

create or replace transient table dw_dev.dev_jkizer.prov_incentive_hbp_control
    copy grants
    
    
    as (with hbp_payer_patients as ( -- grab denominator of patients and current payer status from quality gap files
	select
		suvida_id,
		year(measure_year) as measure_year,
		greatest_ignore_nulls(measure_numerator, suvida_numerator) as measure_numerator,
		1 as measure_denominator,
		report_date,
		evidence_desc as cpt_codes,
	from dw_dev.dev_jkizer.patient_quality_measure
	where quality_measure = 'Controlling Blood Pressure'
	and is_measure_year_current_report = true
)
select	
	measure_year,
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
	'hbp_control' as measure_name,
	concat(
		'Code: ', coalesce(hbp.cpt_codes, ' '), ' ', 
		/*'Code Date: ', coalesce(to_varchar(hbp.cpt_date), ' '), ' | ',*/
		'Payer Status: ', coalesce(to_varchar(measure_numerator), ' '), ' ',
		'Payer Date: ', coalesce(to_varchar(report_date), ' ')
	) as measure_detail,
	measure_numerator,
	hbp.measure_denominator
from dw_dev.dev_jkizer.patient_summary ps
inner join hbp_payer_patients hbp
	on ps.suvida_id = hbp.suvida_id
where ps.is_active_patient = 1
group by all
    )
;


  