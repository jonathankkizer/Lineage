
  create or replace   view dw_dev.dev_jkizer.patient_roster_ghh
  
  copy grants
  
  
  as (
    

with consents_cte  as (
	select distinct
		ID as id,
		case
		  when CONSENTED = '0' then 'OO'
		  when to_boolean(CONSENTED) = FALSE then 'OO'
		  when CONSENTED = '1' then 'OI'
		  when to_boolean(CONSENTED) = TRUE then 'OI'
		end as consent,
		to_varchar(max(to_date(LAST_MODIFIED_DATE)), 'MM/dd/yyyy') as consent_date
	from source_prod.misc.src_ehd_patient_consents
	where last_modified_date is not null
	group by ID, CONSENTED
)
select
	cast(elation_id as decimal(38, 0)) as "Identifier",
	coalesce(last_name, '') as "Last Name",
	coalesce(first_name, '') as "First Name",
	case
        when middle_name is not null then middle_name
        when middle_initial is not null then middle_initial
        else ''
    end as "Middle Name",
	coalesce(to_varchar(birth_date, 'MM/dd/yyyy'), '') as "DOB",
	case
		when gender = 'f' then 'F'
		when gender = 'm' then 'M'
		else ''
	end as "Gender",
	'' as "SSN",
	coalesce(address_line_1, '') as "Street Address 1",
	coalesce(address_line_2, '') as "Street Address 2",
	coalesce(city, '') as "City",
	coalesce(state, '') as "State",
	zip as "Zip",
	coalesce(phone, '') as "Phone",
	coalesce(
		iff(pt.roi_form_due_ind = 0, 'OI', null),
		case when pt.has_data_sharing_consent = true and consent_date is not null then 'OI'
			when pt.has_data_sharing_consent = false then 'OO'
			else 'OO' end
		) 
	as "Consent",
	coalesce(pt.roi_most_recent_completion_date, consent_date) as "Consent_Date"
from dw_dev.dev_jkizer.patient_summary pt
left join consents_cte 
	on pt.elation_id = consents_cte.id
where is_active_assignment = 1
and elation_id is not null
and state = 'tx'
  );

