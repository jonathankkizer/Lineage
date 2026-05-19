/* New Datamart -- Patient AWV Process */
/* 1 record per patient per AWV */
/* Tracks completion of activities that should happen during AWV, including screeners */
/* We may need to remove row_number() filter from fct_patient_history, and instead have it as a column + set = 1 in patient_history datamart (to only get latest value per history type per patient in that datamart), while still getting historical data in this view */
with hra_data as (
	select
		suvida_id,
		max(date(completed_at_datetime)) as form_completion_date
	from dw_dev.dev_jkizer.fct_form_response
	where form_family = 'hra'
	group by suvida_id, year(completed_at_datetime)
), awv_data as (
	select
		fe.encounter_skey,
		fe.appointment_encounter_skey,
		fe.suvida_id,
		fe.visit_note_name,
		fe.encounter_date,
		fe.encounter_datetime,
		fe.note_text,
		fe.signed_date,
		fe.signed_datetime,
		fe.num_working_days_to_note_signing,
		fe.note_signed_on_time,
		fe.billing_date,
		fe.provider_name,
		fe.service_location_name,
		fp.is_awv,
		fp.cpt_code,
		/* PHQ-2 */
		iff(phq2.suvida_id is not null, true, false) as is_phq2_complete,
		phq2.history_value_numeric as phq2_score,
		iff(phq2.history_value_numeric > 3, true, false) as is_phq2_positive, -- check this value w/ Laura Arredondo ; chatGPT
		/* PHQ-9 */
		iff(phq9.suvida_id is not null, true, false) as is_phq9_complete,
		phq9.history_value_numeric as phq9_score,
		iff(phq9.history_value_numeric > 10, true, false) as is_phq9_positive,
		/* GAD-7 */
		iff(gad7.suvida_id is not null, true, false) as is_gad7_complete,
		gad7.history_value_numeric as gad7_score,
		iff(gad7.history_value_numeric > 10, true, false) as is_gad7_positive,
		/* AUDIT-C */
		iff(auditc.suvida_id is not null, true, false) as is_auditc_complete,
		auditc.history_value_numeric as auditc_score,
		/* Smoking Status */
		iff(smok.suvida_id is not null, true, false) as is_smoking_status_complete,
		smok.history_value as smoking_status,
		/* KATZ-ADL */
		iff(adl.suvida_id is not null, true, false) as is_katz_adl_complete,
		adl.history_value_numeric as katz_adl_score,
		/*physical activity */
		iff(pa.suvida_id is not null, true,false) as is_physical_activity_complete,
		/* hra completion */
		iff(hra.suvida_id is not null, true,false) as is_hra_complete
	from dw_dev.dev_jkizer.fct_encounter fe
	inner join dw_dev.dev_jkizer.fct_procedure fp
		on fe.encounter_skey = fp.encounter_skey
	left join dw_dev.dev_jkizer.fct_patient_history phq2
		on fe.suvida_id = phq2.suvida_id
		and fe.encounter_date = date(phq2.creation_datetime)
		and phq2.history_type = 'PHQ-2'
		and phq2.patient_history_index = 1
	left join dw_dev.dev_jkizer.fct_patient_history phq9
		on fe.suvida_id = phq9.suvida_id
		and fe.encounter_date = date(phq9.creation_datetime)
		and phq9.history_type = 'PHQ-9'
		and phq9.patient_history_index = 1
	left join dw_dev.dev_jkizer.fct_patient_history gad7
		on fe.suvida_id = gad7.suvida_id
		and fe.encounter_date = date(gad7.creation_datetime)
		and gad7.history_type = 'GAD-7'
		and gad7.patient_history_index = 1
	left join dw_dev.dev_jkizer.fct_patient_history auditc
		on fe.suvida_id = auditc.suvida_id
		and fe.encounter_date = date(auditc.creation_datetime)
		and auditc.history_type = 'Alcohol use'
		and auditc.patient_history_index = 1
	left join dw_dev.dev_jkizer.fct_patient_history smok
		on fe.suvida_id = smok.suvida_id
		and fe.encounter_date = date(smok.creation_datetime)
		and smok.history_type = 'SmokingStatus'
		and smok.patient_history_index = 1
	left join dw_dev.dev_jkizer.fct_patient_history adl
		on fe.suvida_id = adl.suvida_id
		and fe.encounter_date = date(adl.creation_datetime)
		and adl.history_type = 'KATZ-ADL'
		and adl.patient_history_index = 1
	left join hra_data  hra 
		on fe.suvida_id = hra.suvida_id 
		and fe.encounter_date = hra.form_completion_date
	left join dw_dev.dev_jkizer.fct_patient_history  pa 
		on fe.suvida_id = pa.suvida_id 
		and fe.encounter_date = date(pa.creation_datetime)
		and lower(pa.history_value) like '%physical activity%'
		and pa.patient_history_index = 1
	where fp.is_awv = true
)
select 
	*,
	iff(
			is_phq2_complete = true and 
			is_gad7_complete = true and 
			is_auditc_complete = true and 
			is_smoking_status_complete = true and 
			is_katz_adl_complete = true and 
			-- is_physical_activity_complete = true and
			is_hra_complete = true,
		true, 
		false) 
	as are_forms_completed,
	iff(row_number() over (partition by suvida_id, year(encounter_date) order by encounter_date desc) > 1, true, false) as is_suspected_duplicate_awv,
from awv_data