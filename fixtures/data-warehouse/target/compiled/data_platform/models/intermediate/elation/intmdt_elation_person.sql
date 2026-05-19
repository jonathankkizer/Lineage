with elation_ins as (
	select
		ins.patient_id,
		ins.insurance_name,
		ins.insurance_member_id,
		ins.insurance_group_id,
		ins.insurance_plan,
		ins.insurance_rank,
		row_number() over (partition by patient_id order by ins.last_modified_datetime desc) as _rn
	from dw_dev.dev_jkizer_staging.stg_elation_patient_insurance ins
	where ins.insurance_rank = 1
	and ins._is_deleted_record = 0
	and ins._idx = 1
), elation_pat_phone_primary as (
	select
		p.patient_id,
		p.phone_type,
		p.phone
	from dw_dev.dev_jkizer_staging.stg_elation_patient_phone p
	where p._is_deleted_record = 0
	and p._idx = 1
	and p.phone_priority_ranking = 1
), elation_pat_phone_secondary as (
	select
		p.patient_id,
		p.phone_type as secondary_phone_type,
		p.phone as secondary_phone
	from dw_dev.dev_jkizer_staging.stg_elation_patient_phone p
	where p._is_deleted_record = 0
	and p._idx = 1
	and p.phone_priority_ranking = 2
)
select
	el.elation_id,
	el.source,
	el.first_name,
	el.last_name,
	el.middle_name,
	el.middle_initial,
	el.preferred_name,
	el.suffix,
	el.prefix,
	el.birth_date,
	el.deceased_date,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	el.is_ssn_available,
	el.address_line_1,
	el.address_line_2,
	el.city,
	el.state,
	el.zip,
	case 
		when lower(el.gender_sex) = 'female' then 'f' 
		when lower(el.gender_sex) = 'male' then 'm' 
		else lower(el.gender_sex) 
	end as gender,
	el.marital_status,
	el.occupation,
	el.patient_status,
	el.has_patient_passport,
	el.preferred_language,
	el.spanish_preferred_ind,
	el.english_preferred_ind,
	el.preferred_service_location_id,
	el.race,
	el.secondary_race,
	el.ethnicity,
	el.hispanic_latino_ethnicity_ind,
	el.has_data_sharing_consent,
	el.email,
	el.emergency_contact_first_name,
	el.emergency_contact_last_name,
	el.emergency_contact_phone,
	el.emergency_contact_address_line1,
	el.emergency_contact_address_line2,
	el.emergency_contact_city,
	el.emergency_contact_state,
	el.emergency_contact_zip,
	el.emergency_contact_relationship,
	p.phone_type,
	p.phone,
	p2.secondary_phone_type,
	p2.secondary_phone,
	ins.insurance_name,
	ins.insurance_member_id,
	ins.insurance_group_id,
	ins.insurance_plan,
	el.pref_pharmacy1_ncpdpid,
	el.pref_pharmacy1_name,
	el.pref_pharmacy1_address,
	el.pref_pharmacy1_phone,
	el.pref_pharmacy2_ncpdpid,
	el.pref_pharmacy2_name,
	el.pref_pharmacy2_address,
	el.pref_pharmacy2_phone,
	el.notes,
	el._last_sync_date
from dw_dev.dev_jkizer_staging.stg_elation_patient el
left join elation_ins ins
	on el.elation_id = ins.patient_id
	and ins._rn = 1
left join elation_pat_phone_primary p
	on el.elation_id = p.patient_id
left join elation_pat_phone_secondary p2
	on el.elation_id = p2.patient_id
where el._is_deleted_record = 0
and el._is_test_patient = 0
and el._idx = 1