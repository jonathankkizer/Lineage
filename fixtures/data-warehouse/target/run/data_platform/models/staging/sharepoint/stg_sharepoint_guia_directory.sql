
  create or replace   view dw_dev.dev_jkizer_staging.stg_sharepoint_guia_directory
  
  copy grants
  
  
  as (
    with guia_directory as (
	select
		trim("GUIA FIRST AND LAST NAME") as guia_name,
		iff(lower(active) = 'yes', true, false) as is_active,
		trim(role) as role,
		trim(city) as city,
		trim(state) as state,
		trim(clinic) as clinic,
		trim(city) || ' - ' || trim(clinic) as location_name,
		try_to_date("START DATE", 'yyyy-mm-dd') as guia_start_date,
		try_to_date("EMPLOYEE DEPARTURE DATE", 'yyyy-mm-dd') as guia_end_date,
		replace(trim("EMAIL ADDRESS"), '\n', '') as guia_email_address,
		trim(notes) as notes,
		trim("Elation Guia Tag") as tag_guia_role_name,
	from source_prod.sharepoint.src_sharepoint_guia_directory
	where "EMAIL ADDRESS" is not null
), guia_directory_and_location as (
	select * exclude (location_name), 
		case
			when location_name = 'Tucson - South Tucson' then 'Tucson - South'
			when location_name = 'Phoenix - Central Phoenix' then 'Phoenix - Central'
			when location_name = 'Dallas/FT Worth - Northside' then 'Ft Worth - Northside'
			when location_name = 'Tucson - Tucson West' then 'Tucson - West'
			when location_name = 'Tucson - Tucson South' then 'Tucson - South'
			when location_name = 'Dallas/FT Worth - Oak Cliff' then 'Dallas - Oak Cliff'
			else location_name
		end as location_name,
	from guia_directory
)
select
	gdl.*,
	eu.user_id,
from guia_directory_and_location gdl
left join dw_dev.dev_jkizer_staging.stg_elation_user eu 
on gdl.guia_email_address = eu.user_email
  );

