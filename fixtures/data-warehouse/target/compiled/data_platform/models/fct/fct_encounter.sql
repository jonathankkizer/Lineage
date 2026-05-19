with suvida_clinical_npis as (
	select 
		npi_number 
	from dw_dev.dev_jkizer.intmdt_rippling_provider_staff
	where is_actively_seeing_patients = true
),
encounter_data as (
	select
		md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(b.bill_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.visit_note_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.document_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.signed_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(u_phy.npi as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as encounter_skey,
		md5(cast(coalesce(cast(vn.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.document_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.physician_user_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as appointment_encounter_skey,
		siw.suvida_id,
		vn.patient_id,
		vn.visit_note_name,
		vn.document_date as encounter_date,
		vn.document_datetime as encounter_datetime,
		null as note_text,
		vn.signed_date,
		vn.signed_datetime,
		vn.visit_note_id,
		null as non_visit_note_id,
		vn.signed_by_user_id,
		b.bill_id,
		b.billing_date,
		u_phy.user_name as provider_name,
		u_sign.user_name as signed_by_provider_name,
		u_cre.user_name as bill_created_user_name,
		iff(b.created_by_user_id in (1616564, 1916540, 1406641, 1532886, 1876276), true, false) as is_coder_created,
		vn.physician_user_id,
		u_phy.npi,
		sl.service_location_name,
		'Elation' as source,
	from dw_dev.dev_jkizer_staging.stg_elation_bill b
	inner join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn 
		on b.visit_note_id = vn.visit_note_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_user u_phy
		on vn.physician_user_id = u_phy.user_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_user u_cre
		on b.created_by_user_id = u_cre.user_id
	left join dw_dev.dev_jkizer_staging.stg_elation_user u_sign
		on vn.signed_by_user_id = u_sign.user_id
		and u_sign._idx = 1
	left join dw_dev.dev_jkizer.suvida_id_walk siw 
		on vn.patient_id = siw.member_id
		and siw.source = 'Elation'
	left join suvida_clinical_npis scn 
		on u_phy.npi = to_varchar(scn.npi_number)
	left join dw_dev.dev_jkizer_staging.stg_elation_service_location sl
		on b.service_location_id = sl.service_location_id
	where vn._is_deleted_record = 0
	and b._idx = 1 
	and vn._idx = 1
	and u_phy._idx = 1
	and vn._is_test_patient = 0
	and sl.deletion_datetime is null
), pharm_encounter_data as (
	select
		md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.visit_note_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.document_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.signed_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(u.npi as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as encounter_skey,
		md5(cast(coalesce(cast(vn.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.document_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.physician_user_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as appointment_encounter_skey,
		siw.suvida_id,
		vn.patient_id,
		vn.visit_note_name,
		vn.document_date as encounter_date,
		vn.document_datetime as encounter_datetime,
		null as note_text,
		vn.signed_date,
		vn.signed_datetime,
		vn.visit_note_id,
		null as non_visit_note_id,
		vn.signed_by_user_id,
		null as bill_id, -- no billing info for pharm visits
		null as billing_date, -- no billing info for pharm visits
		u.user_name as provider_name,
		u_sign.user_name as signed_by_provider_name,
		null as bill_created_user_name,
		null as is_coder_created,
		vn.physician_user_id,
		u.npi,
		null as service_location_name,
		'Elation' as source
	from dw_dev.dev_jkizer_staging.stg_elation_visit_note vn
	left join dw_dev.dev_jkizer_staging.stg_elation_bill b
		on vn.visit_note_id = b.visit_note_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_user u
		on vn.physician_user_id = u.user_id
	left join dw_dev.dev_jkizer_staging.stg_elation_user u_sign
		on vn.signed_by_user_id = u_sign.user_id
		and u_sign._idx = 1
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on vn.patient_id = siw.member_id
		and siw.source = 'Elation'
	left join suvida_clinical_npis scn 
		on u.npi = to_varchar(scn.npi_number)
	where visit_note_name = 'Pharmacy Note'
	and deleted_date is null
	and b.bill_id is null
	and vn._idx = 1
	and u._idx = 1
	and vn._is_test_patient = 0
), rn_guia_encounter_data as (
	select
		md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(nvn.non_visit_note_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(nvn.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(nvn.document_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(nvn.signed_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(u.npi as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as encounter_skey,
		null as appointment_encounter_skey,
		siw.suvida_id,
		nvn.elation_id as patient_id,
		nvn.note_type as visit_note_name,
		nvn.document_date as encounter_date,
		nvn.document_datetime as encounter_datetime,
		nvnb.text as note_text,
		nvn.signed_date,
		nvn.signed_datetime,
		null as visit_note_id,
		nvn.non_visit_note_id,
		nvn.signed_by_user_id,
		null as bill_id, -- no billing info for pharm visits
		null as billing_date, -- no billing info for pharm visits
		u.user_name as provider_name,
		u.user_name as signed_by_provider_name,
		null as bill_created_user_name,
		null as is_coder_created,
		null as physician_user_id,
		u.npi,
		null as service_location_name,
		'Elation' as source
	from dw_dev.dev_jkizer_staging.stg_elation_non_visit_note nvn
	left join dw_dev.dev_jkizer_staging.stg_elation_non_visit_note_bullet nvnb
		on nvn.non_visit_note_id = nvnb.non_visit_note_id
		and nvnb.sequence = 0
	inner join dw_dev.dev_jkizer_staging.stg_elation_user u
			on nvn.signed_by_user_id = u.user_id
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on nvn.elation_id = siw.member_id
		and siw.source = 'Elation'
	where nvn._is_test_patient = 0
), union_data as (
	select 
		*,
		'clinical_encounter' as encounter_type,
		row_number() over (partition by suvida_id order by encounter_datetime desc, signed_datetime desc) as encounter_type_idx
	from encounter_data
	union all
	select 
		*,
		'pharm_encounter' as encounter_type,
		row_number() over (partition by suvida_id order by encounter_datetime desc, signed_datetime desc) as encounter_type_idx
	from pharm_encounter_data
	union all
	select
		*,
		case 
			when lower(note_text) ilike '%#medadh%' then 'med_adherence_note' 
			else 'non_visit_encounter' 
		end as encounter_type,
		row_number() over (partition by suvida_id, case 
				when lower(note_text) ilike '%#medadh%' then 'med_adherence_note' 
				else 'non_visit_encounter' 
			end order by encounter_datetime desc, signed_datetime desc) as encounter_type_idx
	from rn_guia_encounter_data
), signed_7_business_days as ( -- calculate for each encounter whether the note was signed within 3 business days
	select
		encounter_skey,
		count(iff(is_workday = 1, dd.date_day, null)) as num_working_days_to_note_signing,
		count(dd.date_day) as num_days_to_note_signing
	from union_data ed
	inner join dw_dev.dev_jkizer.dim_date dd
		on dd.date_day between ed.encounter_date and ed.signed_date
	group by encounter_skey
)
select 
	ed.*,
	sbd.num_working_days_to_note_signing,
	iff(sbd.num_working_days_to_note_signing <= 7 or sbd.num_days_to_note_signing <=7, true, false) as note_signed_on_time,
from union_data ed 
left join signed_7_business_days sbd
	on ed.encounter_skey = sbd.encounter_skey