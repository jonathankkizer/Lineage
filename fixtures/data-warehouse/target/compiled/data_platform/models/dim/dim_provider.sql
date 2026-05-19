select
	seu.npi,
	seu.user_id,
	seu.canonical_physician_id,
	seu.physician_id,
	seu.user_email,
	spl.full_name as provider_name, -- prefer name formatting per Sharepoint list
	seu.user_name,
	seu.user_first_name,
	seu.user_last_name,
	seu.user_type,
	seu.specialty_desc,
	seu.credentials,
	loc.market_name,
	loc.mapped_work_location,
	trim(concat(loc.market_name, ' - ', loc.mapped_work_location)) as location_name,
	spl.work_location_city as location_city,
	spl.work_location,
	work_location_state as location_state,
	spl.title,
	spl.is_actively_seeing_patients,
	case
		when spl.title ilike '%physician%' or title ilike '%provider%' or title ilike '%chief health officer%' then 'PCP'
		when spl.title ilike '%nurse practitioner%' then 'NP'
		when spl.title ilike '%mental health%' then 'MH'
		when spl.title ilike '%dietitian%' or title ilike '%lifestyle%' then 'RD'
		when spl.title ilike '%physical therap%' then 'PT'
		when spl.title ilike '%pharm%' then 'Pharm'
		else spl.title
	end as provider_type
from dw_dev.dev_jkizer_staging.stg_elation_user seu
inner join dw_dev.dev_jkizer.intmdt_rippling_provider_staff spl -- providers must be in sharepoint list
	on to_varchar(trim(seu.npi)) = to_varchar(trim(spl.npi_number))
left join dw_dev.dev_jkizer_source.map_rippling_locations loc 
	on loc.work_location_city = spl.work_location_city 
	and loc.work_location = spl.work_location
where len(seu.npi) > 1 -- guarantee we are grabbing providers by looking for NPI being completed
and seu._idx = 1
and (seu.user_email not ilike '%disabled%' or seu.user_email is null)