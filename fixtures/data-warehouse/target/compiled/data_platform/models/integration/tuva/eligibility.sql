with assignment as ( -- pull min and max regardless of gaps; always join back to patient assignment for membership source of truth
	select 
		suvida_id,
		assignment_source as source,
		assignment_member_id as member_id,
		date_month as enrollment_start_date,
		last_day(date_month, month) as enrollment_end_date,
	from dw_dev.dev_jkizer.patient_assignment
	where assignment_month_ind = 1
	union all
	select
		suvida_id,
		financial_source,
		member_id,
		financial_member_month as enrollment_start_date,
		last_day(financial_member_month, month) as enrollment_end_date,
	from dw_dev.dev_jkizer.patient_financial_membership
	where financial_member_month_ind = 1
)	
select 
	a.suvida_id as person_id,
	a.member_id as member_id,
	a.member_id as subscriber_id,
	case 
		when dp.gender = 'm' then 'male'
		when dp.gender = 'f' then 'female'
		when dp.gender = 'male' then 'male'
		when dp.gender = 'female' then 'female'
		else 'unknown' 
	end as gender,
	dp.race,
	dp.birth_date,
	null as death_date,
	null as death_flag,
	a.enrollment_start_date,
	a.enrollment_end_date,
	a.source as payer,
	null as payer_type,
	a.source as plan,
	null as subscriber_relation,
	dp.original_reason_entitlement_code,
	null as dual_status_code, -- FIX THIS; add dual_status_code to dim_patient
	null as medicare_status_code,
	null as group_id,
	null as group_name,
	dp.first_name,
	dp.last_name,
	dp.address_line_1 as address,
	dp.city,
	dp.state,
	dp.zip as zip_code,
	dp.phone,
	a.source as data_source,
	null as ethnicity,
	null as middle_name,
	null as name_suffix,
	null as email,
	null as social_security_number,
	null as file_name,
	null as file_date,
	null as ingest_datetime,
from assignment a 
inner join dw_dev.dev_jkizer.patient_summary dp 
	on a.suvida_id = dp.suvida_id
qualify row_number() over (partition by person_id, enrollment_start_date, enrollment_end_date order by person_id, data_source) = 1