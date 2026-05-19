
  
    

create or replace transient table dw_dev.dev_jkizer.dim_patient
    copy grants
    
    
    as (with first_enrollment_pts as (
	select
		siw.suvida_id,
		min(fam.assignment_month) as eligibility_start_month,
		max(fam.assignment_month) as eligibility_max_month,
		case 
			when datediff(month, min(fam.assignment_month), current_date()) < 0 then null 
			else datediff(month, min(fam.assignment_month), current_date()) 
		end as num_months_since_eligibility_acquisition,
		count(distinct fam.assignment_month) as num_assignment_months
	from dw_dev.dev_jkizer.fct_assignment_month fam
	inner join dw_dev.dev_jkizer.suvida_id_walk siw 
		on fam.member_id = siw.member_id
		and fam.source = siw.source
	group by siw.suvida_id
), supi_enrollment as (
	select
		fam.member_id,
		dmp.payer_parent,
		dmp.payer_name,
		dmp.payer_contract,
		dmp.plan_code as payer_plan_code,
		dmp.plan_name as payer_plan_name,
		dmp.plan_network_type,
		dmp.plan_program_type,
		dmp.plan_network_program_type,
		fam.source as source,
		dmp.dual_status,
		dmp.language_preference,
		dmp.age_year,
		dmp.birth_date,
		dmp.agent_number,
		dmp.agent_info,
		dmp.address_line_1,
		dmp.address_line_2,
		dmp.city,
		dmp.state,
		dmp.zip,
		dmp.phone,
		dmp.email,
		dmpr.suvida_roster_provider_name,
		dmpr.suvida_roster_npi,
		dmpr.market_name,
		dmpr.location_state,
		iff(fam.is_future_month = true, 1, 0) as is_future_enrollment,
		dmp.gender,
		dmp.medicare_beneficiary_id,
		siw.suvida_id
	from dw_dev.dev_jkizer.fct_assignment_month fam 
	inner join dw_dev.dev_jkizer.dim_assignment_patient dmp 
		using (member_file_skey)
	inner join dw_dev.dev_jkizer.dim_assignment_provider dmpr
		using (provider_file_skey)
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on fam.source = siw.source
		and fam.member_id = siw.member_id
	where (fam.is_current_month = true or 
			(fam.is_future_month = true and current_date() >= dateadd(day, -21, fam.assignment_month))
		)
	qualify row_number() over (partition by siw.suvida_id order by dmp.report_date desc) = 1 -- guarantees one record per patient per month, using the latest record for each month
), latest_medicare_beneficiary_id as (
	select
		siw.suvida_id,
		dmp.medicare_beneficiary_id
	from dw_dev.dev_jkizer.fct_assignment_month fam
	inner join dw_dev.dev_jkizer.dim_assignment_patient dmp
		using (member_file_skey)
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on fam.source = siw.source
		and fam.member_id = siw.member_id
	where dmp.medicare_beneficiary_id is not null
	qualify row_number() over (partition by siw.suvida_id order by fam.assignment_month desc, dmp.report_date desc) = 1
), emr_person as (
	select 
		siw.suvida_id,
		sep.elation_id,
		sep.preferred_service_location_id,
		sep._creation_date as creation_date,
        row_number() over (partition by siw.suvida_id order by sep.last_modified_datetime desc) as _rn
	from dw_dev.dev_jkizer.suvida_id_walk siw
	left join dw_dev.dev_jkizer_staging.stg_elation_patient sep 
		on siw.member_id = sep.elation_id
	where siw.source = 'Elation'
	and sep._deletion_date is null
	and sep._is_test_patient = 0
	and sep._idx = 1
), no_emr_match_suvida_id_walk as ( -- CTE used when no Elation match exists _idx exists to prevent duplication due to one patient having multiple payer IDs prior to EMR account creation
	select
		suvida_id,
		ipi.member_id,
		ipi.source,
		ipi.first_name,
		ipi.last_name,
		ipi.middle_name,
		ipi.middle_initial,
		ipi.birth_date,
		ipi.age_year,
		ipi.address_line_1,
		ipi.address_line_2,
		ipi.city,
		ipi.state,
		ipi.zip,
		ipi.gender,
		ipi.phone,
		-- ipi.is_future_enrollment,
		ipi._last_sync_date,
		row_number() over (partition by siw.suvida_id order by ipi._last_sync_date desc) as _idx
	from dw_dev.dev_jkizer.suvida_id_walk siw
	inner join dw_dev.dev_jkizer.int_suvida_id_input ipi
		on siw.member_id = ipi.member_id
		and siw.source = ipi.source
	where siw.source != 'SalesForce'
), risk_stratification as (
	select
		suvida_id,
		model_type,
		risk_level,
	from dw_dev.dev_jkizer.fct_risk_stratification rs
	where model_run_order = 1
), risk_strat_pivot as (
	select 
		$1 as suvida_id, -- refer to index position due to casing; same as saying "select 1st column"
		$2 as readmission_risk_level,
		$3 as ed_utilizer_risk_level,
		$4 as unplanned_admission_risk_level,
		$5 as dialysis_risk_level,
		$6 as mortality_risk_level,
	from risk_stratification rs
		pivot(max(risk_level) for model_type in ('readmission','ed_utilizer','unplanned_admission','dialysis','mortality')) as p
)
select
	siw.suvida_id,
	ep.elation_id,
	sfp.sf_contact_id as sf_account_id, -- CLEANUP: rename + handle downstream BI breakages
	ipi.source,
	ipi.first_name,
	ipi.last_name,
	ipi.middle_name,
	ipi.preferred_name,
	ipi.middle_initial,
	coalesce(v.birth_date, ipi.birth_date) as birth_date,
	ipi.deceased_date,
	coalesce(v.age_year, ipi.age_year) as age_year,
	coalesce(ipi.address_line_1, v.address_line_1) as address_line_1,
	coalesce(ipi.address_line_2, v.address_line_2) as address_line_2,
	coalesce(ipi.city, v.city) as city,
	coalesce(ipi.state, v.state) as state,
	coalesce(ipi.zip, v.zip) as zip,
	coalesce(v.gender, ipi.gender) as gender,
	coalesce(ipi.email, v.email) as email,
	coalesce(ipi.phone, v.phone) as phone,
	ipi.phone_type,
	ipi.secondary_phone,
	ipi.secondary_phone_type,
	ipi.marital_status,
	ipi.patient_status as elation_status,
	ipi.has_patient_passport,
	ipi.occupation,
	coalesce(ipi.preferred_language, v.language_preference) as preferred_language,
	ipi.spanish_preferred_ind,
	ipi.english_preferred_ind,
	ipi.race,
	ipi.secondary_race,
	ipi.ethnicity,
	ipi.hispanic_latino_ethnicity_ind,
	ipi.has_data_sharing_consent,
	ipi.insurance_name as elation_insurance_name,
	ipi.insurance_member_id as elation_insurance_member_id,
	ipi.insurance_plan as elation_insurance_plan,
	ipi.pref_pharmacy1_ncpdpid,
	ipi.pref_pharmacy1_name,
	ipi.pref_pharmacy1_address,
	ipi.pref_pharmacy1_phone,
	ipi.pref_pharmacy2_ncpdpid,
	ipi.pref_pharmacy2_name,
	ipi.pref_pharmacy2_address,
	ipi.pref_pharmacy2_phone,
	ep.creation_date,
	concat('https://app.elationemr.com/patient/', ep.elation_id, '/') as elation_patient_url,
	iff((v.member_id is not null and v.is_future_enrollment = 0), 1, 0) as is_active_enrollment, -- deprecate
	to_boolean(coalesce(v.is_future_enrollment, 0)) as is_future_enrollment, -- deprecate
	iff((v.member_id is not null and v.is_future_enrollment = 0), 1, 0) as is_active_assignment,
	to_boolean(coalesce(v.is_future_enrollment, 0)) as is_future_assignment,
	coalesce(v.dual_status, 'Non-Dual') as dual_status,
	iff(v.dual_status = 'Dual', true, false) as dual_status_bool,
	case when v.member_id is not null then v.payer_parent else null end as payer_parent,
	case when v.member_id is not null then v.payer_name else null end as payer_name,
	case when v.member_id is not null then v.payer_contract else null end as payer_contract,
	case when v.member_id is not null then v.payer_plan_code else null end as payer_plan_code,
	case when v.member_id is not null then v.payer_plan_name else null end as payer_plan_name,
	case when v.member_id is not null then v.member_id else null end as payer_member_id,
	case when v.member_id is not null then v.plan_network_type else null end as payer_plan_network_type,
	case when v.member_id is not null then v.plan_program_type else null end as payer_plan_program_type,
	case when v.member_id is not null then v.plan_network_program_type else null end as payer_plan_network_program_type,
	coalesce(
		case when v.member_id is not null then v.medicare_beneficiary_id else null end,
		lmbi.medicare_beneficiary_id
	) as payer_medicare_beneficiary_id,
	coalesce(fpp.provider_name, v.suvida_roster_provider_name, 'Unassigned') as provider_name,
	coalesce(fpp.provider_npi, v.suvida_roster_npi) as provider_npi,
	trim(coalesce(fpl.location_name, 'Unassigned')) as location_name,
	coalesce(fpp.provider_location_state, v.location_state, 'Unassigned') as location_state,
	coalesce(fpp.provider_location_market, v.market_name, 'Unassigned') as market_name,
	coalesce(to_varchar(v.suvida_roster_npi), 'Unassigned') as payer_assigned_npi,
	coalesce(to_varchar(v.suvida_roster_provider_name), 'Unassigned') as payer_assigned_provider_name,
	case when v.member_id is not null then v.agent_number else null end as agent_number,
	case when v.member_id is not null then v.agent_info else null end as agent_info,
	coalesce(dpes.patient_acquisition_type, 'Organic') as patient_acquisition_type, -- default to "Organic"
	fenr.eligibility_start_month,
	fenr.eligibility_max_month,
	fenr.num_months_since_eligibility_acquisition,
	rsp.readmission_risk_level,
	rsp.ed_utilizer_risk_level,
	rsp.unplanned_admission_risk_level,
	rsp.dialysis_risk_level,
	rsp.mortality_risk_level,
from dw_dev.dev_jkizer.suvida_id_walk siw
inner join emr_person ep
	on siw.suvida_id = ep.suvida_id
	and siw.member_id = ep.elation_id
	and ep._rn = 1
inner join dw_dev.dev_jkizer.intmdt_elation_person ipi
	on ep.elation_id = ipi.elation_id
left join supi_enrollment v
	on siw.suvida_id = v.suvida_id
left join latest_medicare_beneficiary_id lmbi
	on siw.suvida_id = lmbi.suvida_id
left join dw_dev.dev_jkizer.fct_patient_provider fpp
	on siw.suvida_id = fpp.suvida_id
left join dw_dev.dev_jkizer.dim_patient_assignment_start dpes
	on siw.suvida_id = dpes.suvida_id
left join first_enrollment_pts fenr
	on siw.suvida_id = fenr.suvida_id
left join dw_dev.dev_jkizer_staging.stg_sf_patient_contact sfp
	on siw.suvida_id = sfp.suvida_id
	and sfp.suvida_id_rank = 1
left join dw_dev.dev_jkizer.fct_patient_location fpl
	on siw.suvida_id = fpl.suvida_id
left join risk_strat_pivot rsp 
	on siw.suvida_id = rsp.suvida_id

union all

select
	siw.suvida_id,
	null as elation_id,
	sfp.sf_contact_id as sf_account_id, -- CLEANUP: rename + handle downstream BI breakages,
	siw.source,
	siw.first_name,
	siw.last_name,
	siw.middle_name,
	null as preferred_name,
	siw.middle_initial,
	coalesce(v.birth_date, siw.birth_date) as birth_date,
	null as deceased_date,
	coalesce(v.age_year, siw.age_year) as age_year,
	siw.address_line_1,
	siw.address_line_2,
	siw.city,
	siw.state,
	siw.zip,
	coalesce(v.gender, siw.gender) as gender,
	null as email,
	siw.phone,
	null as phone_type,
	null as secondary_phone,
	null as secondary_phone_type,
	null as marital_status,
	null as elation_status,
	null as has_patient_passport,
	null as occupation,
	null as preferred_language,
	null as spanish_preferred_ind,
	null as english_preferred_ind,
	null as race,
	null as secondary_race,
	null as ethnicity,
	null as hispanic_latino_ethnicity_ind,
	null as has_data_sharing_consent,
	null as elation_insurance_name,
	null as elation_insurance_member_id,
	null as elation_insurance_plan,
	null as pref_pharmacy1_ncpdpid,
	null as pref_pharmacy1_name,
	null as pref_pharmacy1_address,
	null as pref_pharmacy1_phone,
	null as pref_pharmacy2_ncpdpid,
	null as pref_pharmacy2_name,
	null as pref_pharmacy2_address,
	null as pref_pharmacy2_phone,
	null as creation_date,
	null as elation_patient_url,
	iff((v.member_id is not null and v.is_future_enrollment = 0), 1, 0) as is_active_enrollment, -- deprecate
	to_boolean(coalesce(v.is_future_enrollment, 0)) as is_future_enrollment, -- deprecate
	iff((v.member_id is not null and v.is_future_enrollment = 0), 1, 0) as is_active_assignment,
	to_boolean(coalesce(v.is_future_enrollment, 0)) as is_future_assignment,
	coalesce(v.dual_status, 'Non-Dual') as dual_status,
	iff(v.dual_status = 'Dual', true, false) as dual_status_bool,
	case when v.member_id is not null then v.payer_parent else null end as payer_parent,
	case when v.member_id is not null then v.payer_name else null end as payer_name,
	case when v.member_id is not null then v.payer_contract else null end as payer_contract,
	case when v.member_id is not null then v.payer_plan_code else null end as payer_plan_code,
	case when v.member_id is not null then v.payer_plan_name else null end as payer_plan_name,
	case when v.member_id is not null then v.member_id else null end as payer_member_id,
	case when v.member_id is not null then v.plan_network_type else null end as payer_plan_network_type,
	case when v.member_id is not null then v.plan_program_type else null end as payer_plan_program_type,
	case when v.member_id is not null then v.plan_network_program_type else null end as payer_plan_network_program_type,
	coalesce(
		case when v.member_id is not null then v.medicare_beneficiary_id else null end,
		lmbi.medicare_beneficiary_id
	) as payer_medicare_beneficiary_id,
	coalesce(fpp.provider_name, v.suvida_roster_provider_name, 'Unassigned') as provider_name,
	coalesce(fpp.provider_npi, v.suvida_roster_npi) as provider_npi,
	trim(coalesce(fpl.location_name, 'Unassigned')) as location_name,
	coalesce(fpp.provider_location_state, v.location_state, 'Unassigned') as location_state,
	coalesce(fpp.provider_location_market, v.market_name, 'Unassigned') as market_name,
	coalesce(to_varchar(v.suvida_roster_npi), 'Unassigned') as payer_assigned_npi,
	coalesce(to_varchar(v.suvida_roster_provider_name), 'Unassigned') as payer_assigned_provider_name,
	case when v.member_id is not null then v.agent_number else null end as agent_number,
	case when v.member_id is not null then v.agent_info else null end as agent_info,
	coalesce(dpes.patient_acquisition_type, 'Organic') as patient_acquisition_type, -- default to "Organic"
	fenr.eligibility_start_month,
	fenr.eligibility_max_month,
	fenr.num_months_since_eligibility_acquisition,
	rsp.readmission_risk_level,
	rsp.ed_utilizer_risk_level,
	rsp.unplanned_admission_risk_level,
	rsp.dialysis_risk_level,
	rsp.mortality_risk_level,
from no_emr_match_suvida_id_walk siw
left join emr_person ep
	on siw.suvida_id = ep.suvida_id
	and ep._rn = 1
left join supi_enrollment v
	on siw.suvida_id = v.suvida_id
left join latest_medicare_beneficiary_id lmbi
	on siw.suvida_id = lmbi.suvida_id
left join dw_dev.dev_jkizer.fct_patient_provider fpp
	on siw.suvida_id = fpp.suvida_id
left join dw_dev.dev_jkizer.dim_patient_assignment_start dpes
	on siw.suvida_id = dpes.suvida_id
left join first_enrollment_pts fenr
	on siw.suvida_id = fenr.suvida_id
left join dw_dev.dev_jkizer_staging.stg_sf_patient_contact sfp
	on siw.suvida_id = sfp.suvida_id
	and sfp.suvida_id_rank = 1
left join dw_dev.dev_jkizer.fct_mmr_month fmm
	on siw.suvida_id = fmm.suvida_id
	and fmm.patient_mmr_rank = 1
	and fmm.suvida_id_mmr_rank = 1
left join dw_dev.dev_jkizer.fct_patient_location fpl
	on siw.suvida_id = fpl.suvida_id
left join risk_strat_pivot rsp 
	on siw.suvida_id = rsp.suvida_id
where ep.elation_id is null
and siw._idx = 1
and siw.source != 'SalesForce'
    )
;


  