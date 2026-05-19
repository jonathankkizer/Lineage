
  
    

create or replace transient table dw_dev.dev_jkizer.prov_incentive_med_adherence
    copy grants
    
    
    as (select
	year(measure_year) as measure_year,
    pm.suvida_id,
	ps.elation_id,
	ps.first_name,
	ps.last_name,
	ps.birth_date,
	ps.location_name,
	ps.provider_name,
	ps.num_pcp_visits_ytd_group,
	ps.next_pcp_appt_date,
	'star_measures' as measure_group,
    quality_measure as measure_name,
	concat(
        'Measure: ', measure_name, ' ',
		'Payer Status: ', to_varchar(measure_numerator), ' ',
		'Payer Date: ', to_varchar(report_date)
	) as measure_detail,
    sum(measure_numerator) as measure_numerator,
    sum(measure_denominator) as measure_denominator
from dw_dev.dev_jkizer.patient_med_adherence pm
inner join dw_dev.dev_jkizer.patient_summary ps 
    on ps.suvida_id = pm.suvida_id 
where ps.is_active_patient = 1
and pm.is_measure_year_current_report = true
and is_single_fill = 0
and pm.quality_measure in ('Med Adherence - RAS', 'Med Adherence - Diabetes', 'Med Adherence - Statins')
group by all
    )
;


  