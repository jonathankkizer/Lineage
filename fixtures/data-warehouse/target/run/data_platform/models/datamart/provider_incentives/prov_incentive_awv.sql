
  
    

create or replace transient table dw_dev.dev_jkizer.prov_incentive_awv
    copy grants
    
    
    as (select
	year(period_year) as measure_year,
	pm.suvida_id,
	ps.elation_id,
	ps.first_name,
	ps.last_name,
	ps.birth_date,
	ps.location_name,
	ps.provider_name,
	ps.num_pcp_visits_ytd_group,
	ps.next_pcp_appt_date,
	'awv' as measure_group,
	'awv_completion' as measure_name,
	concat('Last AWV date: ', coalesce(to_varchar(ps.last_awv_date), 'No AWV')) as measure_detail,
	iff(pap.suvida_id is not null, 1, 0) as measure_numerator,
	1 as measure_denominator
from dw_dev.dev_jkizer.patient_monthly pm
left join dw_dev.dev_jkizer.patient_awv_process pap on pap.suvida_id = pm.suvida_id and year(encounter_date) = year(pm.period_year)
left join dw_dev.dev_jkizer.patient_summary ps on ps.suvida_id = pm.suvida_id
where ps.is_active_patient = 1
group by all
    )
;


  