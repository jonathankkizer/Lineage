
  create or replace   view dw_dev.dev_jkizer.patient_roster_new_patients
  
  copy grants
  
  
  as (
    
with 

patient_service_location_distances as (
	select
		pcp.suvida_id,
		pa.address_id,
		sl.state,
		elation_id,
		distance,
		row_number() over (partition by pcp.suvida_id, pa.address_id order by distance asc) as _idx
	from dw_dev.dev_jkizer_staging.patient_center_proximity pcp
	left join dw_dev.dev_jkizer_staging.service_locations sl
		on pcp.service_location_address_id = sl.id
	left join dw_dev.dev_jkizer_staging.patient_addresses pa
		on pcp.patient_address_id = pa.address_id
	group by pcp.suvida_id, pa.address_id, sl.state, elation_id, distance
), 

devoted_lang_pref as (
	select member_id, 
		iff(lower(language_preference) = 'spanish', 'Spanish; Castilian', initcap(language_preference)) as preferred_language,
		row_number() over (partition by member_id order by report_date desc) as _rn
	from dw_dev.dev_jkizer_staging.stg_devoted_enrollment
	order by report_date desc
), 

wellmed_lang_pref as (
	select member_id,
		iff(lower(language_preference) = 'spanish', 'Spanish; Castilian', initcap(language_preference)) as preferred_language,
		row_number() over (partition by member_id order by report_date desc) as _rn
	from dw_dev.dev_jkizer_staging.stg_wellmed_enrollment
	order by report_date desc
)

select 
	pt.elation_id,
	pt.payer_member_id,
	pt.payer_name,
	ps.first_name,
    ps.last_name,
	case
        when pt.middle_name is not null then pt.middle_name
        when pt.middle_initial is not null then pt.middle_initial
        else null
    end as middle_name,
	to_varchar(pt.birth_date, 'yyyy-MM-dd') as dob,
	case 
		when lower(pt.gender) in ('f', 'female') then 'Female'
		when lower(pt.gender) in ('m', 'male') then 'Male'
		else 'Unknown'
	end as sex,
	pt.address_line_1 as address_line1,
	pt.address_line_2 as address_line2,
	cts.city_name as city,
	cts.state_code as state,
	pt.zip,
    trim(to_varchar(payer_assigned_npi)) as primary_care_provider_npi,
	case
		when cts.state_code = 'TX' then '634894427291650'
		when cts.state_code = 'AZ' then '892789108310018'
		when psld.state = 'TX' then '634894427291650'
		when psld.state = 'AZ' then '892789108310018'
		when pr.location_state = 'TX' then '634894427291650'
		when pr.location_state = 'AZ' then '892789108310018'
		else null 
	end as primary_physician,
	'509680731226116' as caregiver_practice,
	pt.race,
	pt.ethnicity,
	pt.marital_status,
	pt.phone as phone1,
    'Main' as phone1_type,
	concat('no-email-', collate(pt.payer_member_id, 'SQL_Latin1_General_CP1_CI_AS'), '@noemail.com') as email,
	case
		when pt.payer_name = 'Devoted' then dlp.preferred_language
		when pt.payer_name = 'UHG/Wellmed' then wlp.preferred_language
	end as preferred_language,
	ppn.emr_carrier_id as insurance_company,
	ppn.plan_group as carrier,
	ppn.emr_plan_name as plan_name,
	ppn.emr_plan_id as plan_id,
	ppn.address as emr_carrier_address,
	ppn.city as emr_carrier_city,
	ppn.state as emr_carrier_state,
	ppn.zip_code as emr_carrier_zip,
	psld.elation_id as preferred_location,
	pt.is_active_assignment,
	ps.unplanned_admission_risk_level
from dw_dev.dev_jkizer.dim_patient pt
left join dw_dev.dev_jkizer.patient_summary ps
	on pt.suvida_id = ps.suvida_id
left join source_prod.misc.src_misc_cities cts
	on trim(pt.city) = lower(cts.city_name)
left join dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_name ppn
	on pt.payer_plan_code = ppn.plan_code and
	   ppn._rn = 1
left join dw_dev.dev_jkizer_staging.patient_addresses pa
	on ps.suvida_id = pa.suvida_id and
	   lower(coalesce(ps.address_line_1, '')) = lower(pa.address_line_1_key) and
	   lower(coalesce(ps.address_line_2, '')) = lower(pa.address_line_2_key) and
	   lower(coalesce(ps.city, '')) = lower(pa.city_key) and
	   lower(coalesce(ps.state, '')) = lower(pa.state_key) and
	   lower(coalesce(ps.zip, '')) = lower(pa.zip_key) and
	   pa._idx = 1 and
	   pa.source = 'Google'
left join patient_service_location_distances psld on
	pt.suvida_id = psld.suvida_id and
	pa.address_id = psld.address_id and
	psld._idx = 1
left join devoted_lang_pref dlp 
	on pt.payer_member_id = dlp.member_id
	and dlp._rn = 1
left join wellmed_lang_pref wlp 
	on pt.payer_member_id = wlp.member_id
	and wlp._rn = 1
left join dw_dev.dev_jkizer.dim_provider pr
	on trim(to_varchar(payer_assigned_npi)) = pr.npi
where
	pt.elation_id is null and 
	pt.eligibility_start_month is not null and 
	(pt.is_active_assignment = 1 or pt.is_future_assignment = 1)
  );

