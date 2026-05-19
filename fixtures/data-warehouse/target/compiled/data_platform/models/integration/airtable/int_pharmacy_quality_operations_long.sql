select
	quality_measure_skey,
	full_name,
	birth_date,
	pqm.suvida_id,
	elation_patient_url,
	coalesce(payer_member_id, elation_insurance_member_id) as payer_member_id,
	location_name,
	provider_name,
	last_pcp_appt_date,
	next_pcp_appt_date,
	measure_source,
	measure_year,
	quality_measure,
	quality_measure_type,
	measure_status,
	measure_detail,
	report_date,
	src_file_name,
	suvida_measure_status,
	evidence_desc as suvida_evidence_desc,
	null as suvida_stage, -- placeholder for potential future logic
from dw_dev.dev_jkizer.patient_quality_measure pqm
left join dw_dev.dev_jkizer.patient_summary ps
	on pqm.suvida_id = ps.suvida_id
where is_measure_year_current_report = true
and quality_measure in ('Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults', 'Concurrent Use of Opioids and Benzodiazepines', 'Polypharmacy: Use of Multiple CNS-Active Medications in Older Adults')
and measure_year = '2025-01-01' -- lock this manually -- so we update this to control which measure year flows to Airtable, and avoid it automatically flipping when the year changes