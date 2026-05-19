with attestation_base as (
	select -- recapture opportunities from prior-year EMR diagnosis information
		fd.attestation_opportunity_skey,
		fd.suvida_id,
		to_varchar(year(fd.diagnosis_date) + 1) as measure_year,
		fd.icd_10_code,
		shr.hcc_version,
		shr.hcc as hcc_category,
		shr.hcc_description,
		fd.provider_name as attestation_source_user_name,
		fd.source_type as attestation_opportunity_source_category,
		fd.source as attestation_opportunity_source,
		fd.diagnosis_date as attestation_source_date,
		null as attestation_opportunity_evidence,
		row_number() over (partition by fd.attestation_opportunity_skey order by fd.diagnosis_date asc) as attestation_asc_index, -- 1 = first data point
		row_number() over (partition by fd.attestation_opportunity_skey order by fd.diagnosis_date desc) as attestation_desc_index, -- 1 = most recent data point
	from dw_dev.dev_jkizer.fct_diagnosis fd
	inner join dw_dev.dev_jkizer_staging.stg_icd_hcc_map icd_hcc
		on icd_hcc.icd_10_code = fd.icd_10_code
		and icd_hcc.payment_year = 2024 -- Dependency -- this table should be updated annually as CMS releases new ICD-HCC mappings
		and icd_hcc.hcc_v28 is not null -- restrict to HCC V28
	inner join  dw_dev.dev_jkizer_staging.stg_hcc_reference shr
		on concat('HCC', icd_hcc.hcc_v28) = shr.hcc
		and shr.hcc_version = 28
	left join dw_dev.dev_jkizer_source.map_acute_icd_10_code aicd
		on fd.icd_10_code = aicd.icd_10_code
	where year(fd.diagnosis_date) < year(current_date()) -- open up measure year based on current date
	and suvida_id is not null
	and source_type = 'emr'
	and aicd.icd_10_code is null
	and coalesce(fd.deferred_bill, false) = false -- exclude diagnoses on deferred (unfinalized) Elation bills

	union all

	select -- payer-reported recapture and suspect measures
		attestation_opportunity_skey,
		suvida_id,
		measure_year,
		icd_10_code,
		hcc_version,
		hcc_category,
		hcc_description,
		null as attestation_source_user_name,
		'payer' as attestation_opportunity_source_category,
		measure_source as attestation_opportunity_source,
		report_date as attestation_source_date,
		null as attestation_opportunity_evidence,
		row_number() over (partition by fcm.attestation_opportunity_skey order by fcm.report_date asc) as attestation_asc_index, -- 1 = first data point
		row_number() over (partition by fcm.attestation_opportunity_skey order by fcm.report_date desc) as attestation_desc_index, -- 1 = most recent data point
	from dw_dev.dev_jkizer.fct_coding_measure fcm
	where fcm.hcc_version = 28 -- restrict to HCC V28
	and fcm.is_icd_available = true
	and fcm.measure_source_year_index = 1
	and suvida_id is not null
	and is_acute_icd = false

	union all

	select -- coder-report suspect, recapture measures
		fcad.attestation_opportunity_skey,
		fcad.suvida_id,
		fcad.measure_year,
		fcad.icd_10_code,
		shr.hcc_version,
		shr.hcc as hcc_category,
		shr.hcc_description,
		fcad.assigned_coder as attestation_source_user_name,
		'coder' as attestation_opportunity_source_category,
		'pre-visit review' as attestation_opportunity_source,
		date(fcad.last_modified_datetime) as attestation_source_date,
		fcad.icd_10_code_evidence as attestation_opportunity_evidence,
		row_number() over (partition by fcad.attestation_opportunity_skey order by date(fcad.last_modified_datetime) asc) as attestation_asc_index, -- 1 = first data point
		row_number() over (partition by fcad.attestation_opportunity_skey order by date(fcad.last_modified_datetime) desc) as attestation_desc_index, -- 1 = most recent data point
	from dw_dev.dev_jkizer.fct_coder_attestation_diagnosis fcad
	inner join dw_dev.dev_jkizer_staging.stg_icd_hcc_map icd_hcc
		on icd_hcc.icd_10_code = fcad.icd_10_code
		and icd_hcc.payment_year = 2024 -- Dependency -- this table should be updated annually as CMS releases new ICD-HCC mappings
		and icd_hcc.hcc_v28 is not null -- restrict to HCC V28
	inner join  dw_dev.dev_jkizer_staging.stg_hcc_reference shr
		on concat('HCC', icd_hcc.hcc_v28) = shr.hcc
		and shr.hcc_version = 28
	left join dw_dev.dev_jkizer_source.map_acute_icd_10_code aicd
		on fcad.icd_10_code = aicd.icd_10_code
	where aicd.icd_10_code is null
	and fcad.coder_attestation_opportunity_index = 1
	and suvida_id is not null
), payer_closure_backstop as (
	select
		attestation_opportunity_skey,
		true as is_payer_complete,
	from dw_dev.dev_jkizer.fct_coding_measure fcm
	where fcm.hcc_version = 28 -- restrict to HCC V28
	and fcm.is_icd_available = true
	and fcm.measure_source_year_index = 1
	and suvida_id is not null
	and is_acute_icd = false
	and measure_status = 'closed'
), diagnosis_closure_backstop as (
	select
		ab.attestation_opportunity_skey,
		max(iff(fd.suvida_id is not null, true, false)) as is_emr_diagnosis_complete,
		min(fd.diagnosis_date) as action_date,
	from attestation_base ab
	left join dw_dev.dev_jkizer.fct_diagnosis fd
		on ab.suvida_id = fd.suvida_id
		and ab.icd_10_code = fd.icd_10_code
		and ab.measure_year = year(fd.diagnosis_date)
		and fd.source_type = 'emr'
	group by all
), elation_accept_dismiss as (
	select
		attestation_opportunity_skey,
		action_event_type as elation_action_type,
		true as is_emr_action_complete,
		date(date_actioned) as action_date,
	from dw_dev.dev_jkizer_staging.stg_attestation_action_event_log
	where attestation_event_index = 1
	and action_event_type in ('accept', 'deny')
), elation_caregap_accept_dismiss_backstop as (
	select
		ael.attestation_opportunity_skey,
		max(iff(cge.reminder_action like '%Yes%', 'accept', 'deny')) as elation_action_type,
		max(true) as is_emr_action_complete,
		min(cge.date) as action_date,
	from dw_dev.dev_jkizer_staging.stg_elation_caregaps cg
	inner join dw_dev.dev_jkizer_staging.stg_elation_caregap_engagement cge
		on cg.caregaps_id = cge.gap_id
	inner join dw_dev.dev_jkizer_staging.stg_attestation_event_log ael
		on cg.caregaps_id = ael.caregap_id
		and ael.action = 'Create'
	group by all
), icd_ref_temp as (
	select
		replace(code, '.', '') as icd_10_code,
		code_description as icd_10_code_description,
	from dw_dev.dev_jkizer_staging.stg_elation_icd10
	where _idx = 1
), problem_list_descs as ( -- grab problem list information, prefer this description where available
	select
		siw.suvida_id,
		pp.patient_problem_id as problem_id,
		pp.problem_description,
		replace(ic.code, '.', '') as icd_10_code,
		ic.code
	from dw_dev.dev_jkizer_staging.stg_elation_patient_problem pp
	inner join dw_dev.dev_jkizer_staging.stg_elation_patient_problem_code ppc
		on pp.patient_problem_id = ppc.patient_problem_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_imo im
		on ppc.imo_code = im.imo_code
	inner join dw_dev.dev_jkizer_staging.stg_elation_icd10 ic
		on ppc.icd10 = ic.icd10_id
		and im.uq_id = ic.imo_id
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on pp.patient_id = siw.member_id
		and siw.source = 'Elation'
	where pp.deletion_datetime is null
	and im.is_deleted = false
	qualify row_number() over (partition by siw.suvida_id, ic.code order by start_date desc, last_modified_datetime desc) = 1 -- grabbing most recent start and, where tie, most recent modified
), aggregated_attestation as (
	select
		/* IDs and keys; uniqueness = 1 row per patient per icd_10_code per measure_year */
		ab.attestation_opportunity_skey,
		ab.suvida_id,
		ab.measure_year,
		ab.icd_10_code,
		pld.problem_id,
		pld.code as problem_list_icd_10_code,
		icdr.icd_10_code_description, -- temp (?) via elation
		pld.problem_description as problem_list_description,
		coalesce(pld.problem_description, icdr.icd_10_code_description) as code_description,
		coalesce(iff(
				(dcb.is_emr_diagnosis_complete = true or ead.is_emr_action_complete = true or dadb.is_emr_action_complete = true or pcb.is_payer_complete = true),
				'closed',
				null),
			'open') as attestation_opportunity_status,
		dcb.is_emr_diagnosis_complete,
		pcb.is_payer_complete,
		coalesce(ead.elation_action_type, dadb.elation_action_type) as elation_action_type,
		coalesce(ead.is_emr_action_complete, dadb.is_emr_action_complete) as is_emr_action_complete,
		least_ignore_nulls(dcb.action_date, ead.action_date, dadb.action_date) as first_action_date,
		max(iff(ael.attestation_opportunity_skey is not null, true, false)) as is_attestation_opportunity_created,
		max(iff(attestation_opportunity_source_category = 'payer', true, false)) as is_payer_opportunity,
		max(iff(attestation_opportunity_source_category = 'emr', true, false)) as is_redoc_opportunity,
		max(iff(attestation_opportunity_source_category = 'coder', true, false)) as is_coder_opportunity,
		nullif(listagg(attestation_opportunity_evidence, ' | '), '') as coder_evidence,
		/* Textual information for gap definition, gap */
		nullif(listagg(distinct 'Relevant HCC(s): ' || hcc_category || ' ' || hcc_description, ' | '), '') as mapped_hccs,
		max(iff(attestation_opportunity_source_category = 'payer' and attestation_desc_index = 1, attestation_source_date, null)) as max_payer_report_date,
		max(iff(attestation_opportunity_source_category = 'payer' and attestation_desc_index = 1, '[Payer] Suspected diagnosis from ' || attestation_opportunity_source, null)) as payer_suspect_info,
		max(iff(attestation_opportunity_source_category = 'emr' and attestation_desc_index = 1, '[Redoc] Last diagnosed by ' || attestation_source_user_name || ' on ' || attestation_source_date, null)) as redoc_info,
		max(iff(attestation_opportunity_source_category = 'coder' and attestation_desc_index = 1, '[Coder]' || ' ' || attestation_source_user_name || ' ' || attestation_opportunity_evidence, null)) as coder_info,
		/* similar pattern for coder data & add to short_text below */
		max(iff(attestation_opportunity_source_category = 'emr' and attestation_desc_index = 1, attestation_source_date, null)) as most_recent_emr_diagnosis_date,
		listagg(distinct attestation_opportunity_source, ' | ') as source
	from attestation_base ab
	left join payer_closure_backstop pcb 
		on ab.attestation_opportunity_skey = pcb.attestation_opportunity_skey
	left join diagnosis_closure_backstop dcb
		on ab.attestation_opportunity_skey = dcb.attestation_opportunity_skey
	left join elation_accept_dismiss ead
		on ab.attestation_opportunity_skey = ead.attestation_opportunity_skey
	left join elation_caregap_accept_dismiss_backstop dadb 
		on ab.attestation_opportunity_skey = dadb.attestation_opportunity_skey
	left join icd_ref_temp icdr
		on ab.icd_10_code = icdr.icd_10_code
	left join problem_list_descs pld
		on ab.suvida_id = pld.suvida_id
		and ab.icd_10_code = pld.icd_10_code
	left join dw_dev.dev_jkizer_staging.stg_attestation_event_log ael
		on ab.attestation_opportunity_skey = ael.attestation_opportunity_skey
		and ael.attestation_process_event_index = 1
	group by all
)
select *
from aggregated_attestation