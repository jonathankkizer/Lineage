

-- Contexture AZ HIE Member File for ADT Notifications
-- Spec: Member-File-Requirements_Contexture_Interactive_09.2025

select
	ps.elation_id as member_id,
	ps.first_name as member_first_name,
	ps.last_name as member_last_name,
	to_char(ps.birth_date, 'MM/DD/YYYY') as member_date_of_birth,
	case
		when lower(ps.gender) in ('f', 'female') then 'F'
		when lower(ps.gender) in ('m', 'male') then 'M'
		else 'U'
	end as member_gender,
	ps.address_line_1 as member_address_1,
	ps.address_line_2 as member_address_2,
	ps.city as member_city,
	ps.state as member_state,
	ps.zip as member_zip_code,
	ps.phone as member_phone_number,
	null as member_social_security_number,
	'ADT Notifications' as enrollment,
	null as transaction_type,
	ps.suvida_id

from dw_dev.dev_jkizer.patient_summary ps

where lower(ps.state) = 'az'
  and ps.deceased_date is null
  and (
      ps.is_active_assignment = 1
      or (ps.is_active_assignment = 0 and ps.next_pcp_appt_date is not null)
      or (ps.is_active_assignment = 0 and ps.is_pcp_visit_complete_ytd = 1)
  )