with users as (
	-- Office Staff (non-physicians) according to Elation
	select
		seu.user_id,
		seu.office_staff_id as user_staff_id,
		seu.physician_id,
		seu.user_email,
		seu.user_name,
		seu.user_first_name,
		seu.user_last_name,
		seu.user_type,
		seu.specialty_desc,
		seu.credentials,
		seu.is_active
	from dw_dev.dev_jkizer_staging.stg_elation_user seu
	where seu.npi is null and
		seu._idx = 1

	union all

	-- Physicians according to Rippling
	select
		seu.user_id,
		seu.office_staff_id as user_staff_id,
		seu.physician_id,
		seu.user_email,
		seu.user_name,
		seu.user_first_name,
		seu.user_last_name,
		seu.user_type,
		seu.specialty_desc,
		seu.credentials,
		iff(spl.is_active = FALSE, spl.is_active, seu.is_active) as is_active
	from dw_dev.dev_jkizer_staging.stg_elation_user seu
	inner join dw_dev.dev_jkizer.intmdt_rippling_provider_staff spl
		on trim(to_varchar(seu.npi)) = trim(to_varchar(spl.npi_number))
	where len(seu.npi) > 1 and
		seu._idx = 1 and
		spl.work_email is not null

	union all

	-- Office Staff (non-physicians) according to Rippling
	select
		seu.user_id,
		seu.office_staff_id as user_staff_id,
		seu.physician_id,
		seu.user_email,
		seu.user_name,
		seu.user_first_name,
		seu.user_last_name,
		seu.user_type,
		seu.specialty_desc,
		seu.credentials,
		iff(spl.is_active = FALSE, spl.is_active, seu.is_active) as is_active
	from dw_dev.dev_jkizer_staging.stg_elation_user seu
	inner join dw_dev.dev_jkizer.dim_rippling_staff spl
		on seu.user_email = spl.work_email and
		spl.npi_number is null and
		spl.is_actively_seeing_patients = FALSE and
		lower(spl.title) not like 'physician'
	where lower(seu.user_type) = 'physician' and
		seu._idx = 1 and
		spl.work_email is not null
),

final_users as (
	select *
	from users
	qualify row_number() over (partition by user_id order by 1 desc) = 1
)

select *
from final_users

union all

select
	seu.user_id,
	seu.office_staff_id as user_staff_id,
	seu.physician_id,
	seu.user_email,
	seu.user_name,
	seu.user_first_name,
	seu.user_last_name,
	seu.user_type,
	seu.specialty_desc,
	seu.credentials,
	seu.is_active
from dw_dev.dev_jkizer_staging.stg_elation_user seu
where len(seu.npi) > 1 and
	seu.is_active = TRUE and
	seu._idx = 1 and 
	not exists
	(
		select 1
		from final_users fu
		where seu.user_email = fu.user_email				
	)