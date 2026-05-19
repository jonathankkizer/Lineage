
  
    

create or replace transient table dw_dev.dev_jkizer.patient_census_event
    copy grants
    
    
    as (with clustered_census_events as (
	select
		fci.suvida_id,
		fci.census_grouping_id,
		fcqg.census_quality_grouping_id,
		min(fce.admit_date) as admit_date,
		date_trunc(month, min(fce.admit_date)) as admit_month,
		max(fce.discharge_date) as discharge_date,
		coalesce(max(fce.discharge_date), min(fce.admit_date)) as effective_discharge_date,
		min(fce.earliest_report_date) as first_report_date,
		min(fce.earliest_discharge_report_date) as first_discharge_report_date,
		max(fce.max_report_date) as max_report_date,
		max(iff(fce.level_of_care = 'inpatient', 1, 0)) as is_inpatient,
		max(iff(fce.level_of_care = 'emergency', 1, 0)) as is_er,
		max(iff(fce.level_of_care = 'observation', 1, 0)) as is_observation,
		max(0) as is_snf,
		max(0) as is_rehab,
		nullif(listagg(dx_code, ' | '), '') as diagnosis_codes,
		nullif(listagg(dx_text, ' | '), '') as diagnosis,
		max(payor_flag) as payor_flag,
		max(hie_flag) as hie_flag,
		nullif(listagg(distinct facility, ' | '), '') as facilities,
		nullif(listagg(distinct data_sources, ' | '), '') as sources,
		nullif(listagg(distinct data_source_types, ' | '), '') as source_types,
		iff(min(fce.admit_date) >= dateadd(month, -12, current_date()), 1, 0) as rolling_12_flag,
		iff(min(fce.admit_date) >= dateadd(month, -3, current_date()), 1, 0) as rolling_3_flag
	from dw_dev.dev_jkizer.fct_census_event fce
	inner join dw_dev.dev_jkizer.fct_census_grouping fci 
		on fce.suvida_id = fci.suvida_id
		and (fce.admit_date between fci.admit_grouping_start_date and fci.admit_grouping_end_date or coalesce(fce.discharge_date, fce.admit_date) between fci.admit_grouping_start_date and fci.admit_grouping_end_date)
	left join dw_dev.dev_jkizer.fct_census_quality_grouping fcqg
		on fce.suvida_id = fcqg.suvida_id
		and fce.admit_date between fcqg.admit_grouping_start_date and fcqg.admit_grouping_end_date
	where level_of_care in ('inpatient', 'emergency', 'observation')
	group by all
), snf_rehab as (
	select
		fce.suvida_id,
		md5(cast(coalesce(cast(fce.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(admit_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(discharge_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(earliest_report_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(max_report_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(data_source_types as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dx_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(facility as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as census_grouping_id,
		null as census_quality_grouping_id,
		fce.admit_date as admit_date,
		date_trunc(month, fce.admit_date) as admit_month,
		fce.discharge_date as discharge_date,
		coalesce(fce.discharge_date, fce.admit_date) as effective_discharge_date,
		fce.earliest_report_date as first_report_date,
		fce.earliest_discharge_report_date as first_discharge_report_date,
		fce.max_report_date as max_report_date,
		0 as is_inpatient,
		0 as is_er,
		0 as is_observation,
		iff(fce.level_of_care = 'skilled_nursing', 1, 0) as is_snf,
		iff(fce.level_of_care = 'rehab', 1, 0) as is_rehab,
		nullif(dx_code, '') as diagnosis_codes,
		nullif(dx_text, '') as diagnosis,
		payor_flag,
		hie_flag,
		nullif(facility, '') as facilities,
		nullif(data_sources, '') as sources,
		nullif(data_source_types, '') as source_types,
		iff(fce.admit_date >= dateadd(month, -12, current_date()), 1, 0) as rolling_12_flag,
		iff(fce.admit_date >= dateadd(month, -3, current_date()), 1, 0) as rolling_3_flag
	from dw_dev.dev_jkizer.fct_census_event fce
	where level_of_care in ('rehab', 'skilled_nursing')
), 

ip_readmissions as (
	select 
		suvida_id, 
		census_grouping_id, 
		admit_date, 
		discharge_date, 
		lag(effective_discharge_date) over (partition by suvida_id order by admit_date asc) as prev_discharge_date,
		datediff(day, lag(effective_discharge_date) over (partition by suvida_id order by admit_date asc), admit_date) as days_since_prev_discharge,
		row_number() over (partition by census_quality_grouping_id order by admit_date asc) as census_quality_admit_index,
	from clustered_census_events 
	where is_inpatient = 1
),

mad_gad_patients as (
	select 
		suvida_id, 
		diagnosis_date
	from dw_dev.dev_jkizer.fct_diagnosis
	where source_type = 'emr' 
	and suvida_id is not null 
	and icd_10_code in ('F5000', 'F319', 'F502', 'F320', 'F321', 'F322', 'F323', 'F324', 'F325', 'F3281', 'F3289', 'F329', 'F330', 'F331', 'F332', 'F333', 'F3341', 'F3342', 'F606', 'F603', 'F607', 'F6081', 'F605', 'F259', 'F209')
	group by all
), combined_census as (
	select *
	from clustered_census_events
	union all
	select *
	from snf_rehab
), events as (
	select
		cc.*,
		iff(mad.suvida_id is not null, 1, 0) as is_mad_gad_patient,
		ip_readmissions.prev_discharge_date,
		ip_readmissions.days_since_prev_discharge,
		ip_readmissions.census_quality_admit_index,
		datediff(day, admit_date, first_report_date) as days_admit_to_notification,
		datediff(day, effective_discharge_date, first_discharge_report_date) as days_discharge_to_discharge_notification,
		iff(discharge_date is not null, true, false) as is_discharge_available,
		datediff(day, admit_date, effective_discharge_date) as length_of_stay,
		min(case when fp.is_pcp = 1 then fp.encounter_date else null end) as post_discharge_pcp_encounter_date,
		datediff(day, effective_discharge_date, min(case when fp.is_pcp = 1 then fp.encounter_date else null end)) as days_post_discharge_pcp_encounter,
		min(phone_fe.encounter_date) as post_discharge_phone_encounter_date,
		least_ignore_nulls(min(case when fp.is_postdischarge_eval = 1 or fp.is_pcp = 1 then fp.encounter_date end)) as post_discharge_pcp_or_patient_eval_date,
		datediff(day, first_report_date, min(phone_fe.encounter_date)) as days_post_discharge_phone_encounter,

		least_ignore_nulls(min(date(office_msg.creation_datetime)), min(phone_tcm.encounter_date)) as post_discharge_phone_tcm_date,
		datediff(day, first_report_date, least_ignore_nulls(min(date(office_msg.creation_datetime)), min(phone_tcm.encounter_date))) as days_post_discharge_phone_tcm,
		least_ignore_nulls(min(date(office_message_tcmutr.creation_datetime)), min(phone_non_visit_tcmutr.encounter_date)) as post_discharge_tcmutr_date,
        datediff(day, first_report_date, least_ignore_nulls(min(date(office_message_tcmutr.creation_datetime)), min(phone_non_visit_tcmutr.encounter_date))) as days_post_discharge_phone_tcmutr,

		min(case when fp.is_postdischarge_medrec = 1 then fp.encounter_date end) as post_discharge_medrec_encounter_date,
		datediff(day, effective_discharge_date, min(case when fp.is_postdischarge_medrec = 1 then fp.encounter_date end)) as days_post_discharge_medrec_encounter,
		min(case when fp.is_postdischarge_eval = 1 then fp.encounter_date end) as post_discharge_eval_encounter_date,
		datediff(day, effective_discharge_date, min(case when fp.is_postdischarge_eval = 1 then fp.encounter_date end)) as days_post_discharge_eval_encounter,
		datediff(day, first_report_date, min(case when fp.is_postdischarge_eval = 1 then fp.encounter_date end)) as days_post_notification_eval_encounter,
		min(date(office_msg.creation_datetime)) as post_notification_office_msg_date,
		datediff(day, first_report_date, min(date(office_msg.creation_datetime))) as days_post_notification_office_msg,
		count(fp_ncm.encounter_date) as ncm_count_within_30_days,
		min(fer.document_date) as post_discharge_summary_report_date,
		datediff(day, effective_discharge_date, min(fer.document_date)) as days_post_discharge_summary_report,
	from combined_census cc
	left join ip_readmissions 
		using (census_grouping_id)
	left join dw_dev.dev_jkizer.fct_encounter phone_fe
		on cc.suvida_id = phone_fe.suvida_id
		and phone_fe.encounter_date >= cc.first_report_date
		and phone_fe.visit_note_name = 'phone'
	left join dw_dev.dev_jkizer.fct_encounter phone_tcm
	-- Report date is used for TCM metric instead of discharge_date because we may receive reports of a discharge days after the actual discharge date
	-- Looks for #phoneTCM in non visit note, phone note, AND office messages below
		on cc.suvida_id = phone_tcm.suvida_id
		and phone_tcm.encounter_date >= cc.first_report_date
		and (lower(phone_tcm.note_text) like ('%phonetcm%') or lower(phone_tcm.note_text) like ('%tcmreceipt%'))
	left join dw_dev.dev_jkizer.fct_office_message office_msg 
		on cc.suvida_id = office_msg.suvida_id
		and date(office_msg.creation_datetime) >= cc.first_report_date 
		and (lower(office_msg.text) like ('%phonetcm%') or lower(office_msg.text) like ('%tcmreceipt%'))
    -- Transitions of Care Management: Unable to Reach - PHONE and Non Visit Note
	left join dw_dev.dev_jkizer.fct_encounter phone_non_visit_tcmutr
			on cc.suvida_id = phone_non_visit_tcmutr.suvida_id
			and phone_non_visit_tcmutr.encounter_date >= cc.first_report_date
			and (lower(phone_non_visit_tcmutr.note_text) like ('%#tcmutr%')) 
	-- Transitions of Care Management: Unable to Reach - office message
	left join dw_dev.dev_jkizer.fct_office_message office_message_tcmutr
			on cc.suvida_id = office_message_tcmutr.suvida_id
			and office_message_tcmutr.creation_datetime >= cc.first_report_date
			and lower(office_message_tcmutr.text) like ('%#tcmutr%') 
	left join dw_dev.dev_jkizer.fct_procedure fp 
		on fp.suvida_id = cc.suvida_id 
		and fp.encounter_date >= cc.effective_discharge_date 
		and (is_postdischarge_medrec = 1 or is_postdischarge_eval = 1 or is_pcp = 1)
	left join dw_dev.dev_jkizer.fct_procedure fp_ncm 
		on fp_ncm.suvida_id = cc.suvida_id 
		and fp_ncm.encounter_date >= cc.effective_discharge_date 
		and fp_ncm.is_postdischarge_eval = 1 
		and datediff(day, cc.effective_discharge_date, fp_ncm.encounter_date) <= 30
	-- MAD/GAD diagnoses apply for a rolling 12m and must be recoded for patients to fall under this category
	left join mad_gad_patients mad 
		on mad.suvida_id = cc.suvida_id 
		and mad.diagnosis_date <= cc.admit_date 
		and datediff(month, diagnosis_date, admit_date) <= 12
	left join dw_dev.dev_jkizer.fct_elation_report fer 
		on cc.suvida_id = fer.suvida_id
		and fer.document_date >= cc.first_report_date
		and fer.document_tag_values ilike '%discharge summary%'
	group by all
),

final_events as (
	select
		*,
		row_number() over (partition by suvida_id order by coalesce(admit_date, discharge_date), sources asc) as patient_event_index,
		array_to_string(
			array_construct_compact(
				iff(is_inpatient = 1, 'IP', null), 
				iff(is_er = 1, 'ER', null), 
				iff(is_observation = 1, 'Obs', null),
				iff(is_snf = 1, 'SNF', null), 
				iff(is_rehab = 1, 'Rehab', null)), 
			' | ')
		as event_type,
from events
),

with_skey as (
	select 
		md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(patient_event_index as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as census_event_skey,
		*
	from final_events
)
-- Compare census admission details to Airtable updates, priority should be given to Airtable
select 
    ws.census_event_skey,
    ws.census_grouping_id,
	ws.suvida_id,
	ws.census_quality_grouping_id,
    ws.admit_date,
    co.admit_date_supplemental,
    coalesce(co.admit_date_supplemental, ws.admit_date) as preferred_admit_date,
	ws.admit_month,
    ws.discharge_date,
    co.discharge_date_supplemental,
    coalesce(co.discharge_date_supplemental, ws.discharge_date) as preferred_discharge_date,
	ws.effective_discharge_date,
    co.is_true_event_supplemental,
    ws.first_report_date,
    ws.first_discharge_report_date,
    ws.max_report_date,
    ws.is_inpatient,
    ws.is_er,
    ws.is_observation,
    ws.is_snf,
    ws.is_rehab,
    ws.diagnosis_codes,
    ws.diagnosis,
    ws.payor_flag,
    ws.hie_flag,
    ws.facilities,
    ws.sources,
    ws.source_types,
    iff(ws.sources = 'Bamboo Health', true, false) as is_bamboo_only_event,
    ws.rolling_12_flag,
    ws.rolling_3_flag,
    ws.is_mad_gad_patient,
    ws.prev_discharge_date,
    ws.days_since_prev_discharge,
    ws.census_quality_admit_index,
    ws.days_admit_to_notification,
	coalesce((datediff(day, discharge_date_supplemental, first_discharge_report_date)), ws.days_discharge_to_discharge_notification) as days_discharge_to_discharge_notification,
    ws.is_discharge_available,
	datediff(day, coalesce(co.admit_date_supplemental, ws.admit_date), coalesce(co.discharge_date_supplemental, ws.effective_discharge_date)) as length_of_stay,
    ws.post_discharge_pcp_encounter_date,
	coalesce(datediff(day, co.discharge_date_supplemental, post_discharge_pcp_encounter_date), ws.days_post_discharge_pcp_encounter) as days_post_discharge_pcp_encounter,
    ws.post_discharge_phone_encounter_date,
    ws.days_post_discharge_phone_encounter,
    ws.post_discharge_pcp_or_patient_eval_date,
    ws.post_discharge_phone_tcm_date,
    ws.days_post_discharge_phone_tcm,
	ws.post_discharge_tcmutr_date,
    ws.days_post_discharge_phone_tcmutr,
    ws.post_discharge_medrec_encounter_date,
	coalesce(datediff(day, co.discharge_date_supplemental, post_discharge_medrec_encounter_date), ws.days_post_discharge_medrec_encounter) as days_post_discharge_medrec_encounter,
    ws.post_discharge_eval_encounter_date,
	coalesce(datediff(day, co.discharge_date_supplemental, post_discharge_eval_encounter_date), ws.days_post_discharge_eval_encounter) as days_post_discharge_eval_encounter,
    ws.days_post_notification_eval_encounter,
    ws.post_notification_office_msg_date,
    ws.days_post_notification_office_msg,
    ws.ncm_count_within_30_days,
    ws.post_discharge_summary_report_date,
	coalesce(datediff(day, discharge_date_supplemental, post_discharge_summary_report_date), ws.days_post_discharge_summary_report) as days_post_discharge_summary_report,
    ws.patient_event_index,
    ws.event_type
from with_skey ws
left join dw_dev.dev_jkizer_staging.stg_airtable_census_operations co 
	on co.census_event_skey = ws.census_event_skey
    )
;


  