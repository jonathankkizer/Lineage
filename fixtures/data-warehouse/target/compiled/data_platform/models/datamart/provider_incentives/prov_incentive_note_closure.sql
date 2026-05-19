select
	year(encounter_date) as measure_year,
	ps.suvida_id,
	ps.elation_id,
	ps.first_name,
	ps.last_name,
	ps.birth_date,
	ps.location_name,
	ps.provider_name,
	ps.num_pcp_visits_ytd_group,
	ps.next_pcp_appt_date,
	'timely_note_closure' as measure_group,
	'visit_note_closure' as measure_name,
	encounter_skey,
	encounter_date,
	signed_date,
	concat(
		'Appt Date: ', to_varchar(encounter_datetime), ' | ',
		'Sign Date: ', coalesce(to_varchar(signed_date), 'Not signed'), ' | ',
		'Encounter Provider: ', to_varchar(vnd.provider_name), ' | ',
		'Encounter ID: ', to_varchar(vnd.encounter_skey)
	) as measure_detail,
	case when note_signed_on_time = 1 then 1 else 0 end as measure_numerator,
	1 as measure_denominator
from dw_dev.dev_jkizer.patient_summary ps
inner join dw_dev.dev_jkizer.patient_encounter vnd
	on ps.suvida_id = vnd.suvida_id
where vnd.encounter_type = 'clinical_encounter'
and vnd.npi = ps.provider_npi
-- Omar wants to only count note closures after 3/15 for 2025
and (year(vnd.encounter_date) = '2024' or vnd.encounter_date >= '2025-03-15')