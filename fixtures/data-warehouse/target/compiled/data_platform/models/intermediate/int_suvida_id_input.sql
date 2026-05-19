-- NOTE: THIS TABLE IS USED AS INPUT FOR Suvida ID Python process don't make changes unless intended
with data as (
select
	dmp.member_id,
	dmp.source as source,
	dmp.first_name,
	dmp.last_name,
	dmp.middle_name,
	dmp.middle_initial,
	dmp.birth_date,
	dmp.age_year,
	dmp.address_line_1,
	dmp.address_line_2,
	dmp.city,
	dmp.state,
	dmp.zip,
	dmp.gender,
	dmp.phone,
	-- dmp.medicare_beneficiary_id, -- TODO: Uncomment when ready to add to entity resolution
	dmp.report_date as _last_sync_date
from dw_dev.dev_jkizer.dim_assignment_patient dmp
qualify row_number() over (partition by dmp.member_id order by patient_report_index asc) = 1
union all
select
	elation_id as member_id,
	source,
	first_name,
	last_name,
	middle_name,
	middle_initial,
	birth_date,
	age_year,
	address_line_1,
	address_line_2,
	city,
	state,
	zip,
	gender,
	phone,
	_last_sync_date
from dw_dev.dev_jkizer.intmdt_elation_person -- elation EMR data
union all
select
	sf_contact_id as member_id,
	_source_system as source,
	lower(first_name) as first_name,
	lower(last_name) as last_name,
	lower(middle_name) as middle_name,
	lower(middle_initial) as middle_initial,
	birth_date,
	age_year,
	lower(address_line_1) as address_line_1,
	lower(address_line_2) as address_line_2,
	lower(city) as city,
	lower(state) as state,
	left(zip, 5) as zip,
	case 
		when lower(gender) = 'female' then 'f' 
		when lower(gender) = 'male' then 'm' 
		else null 
	end as gender,
	phone,
	airbyte_extracted_at as _last_sync_date
from dw_dev.dev_jkizer_staging.stg_sf_patient_contact
where first_name is not null and last_name is not null and birth_date_type = 'actual' -- only picking up real birthdays and where name is not null for normal Suvida process non-actual birthdays were handled in 1x ad hoc run
) 

select * from data where date_trunc('year', birth_date) >= '1900-01-01'