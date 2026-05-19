select
	coalesce(try_to_date(ReportDate, 'mm/dd/yyyy'), try_to_date(ReportDate)) as report_date,
	DevotedID as source_member_id,
	PcpName as pcp,
	CASE
		WHEN AdmissionLevelofCare IN ('Skilled Nursing Care', 'SKILLED_NURSING')
		THEN 'skilled_nursing'
		WHEN AdmissionLevelofCare IN ('REHAB', 'Rehabilitation - Inpatient')
		THEN 'rehab'
		WHEN AdmissionLevelofCare IN ('OBS', 'OBSERVATION')
		THEN 'observation'
		WHEN AdmissionLevelofCare IN ('Hospital - Outpatient', 'OP', 'OUTPATIENT', '102', '104', '106', '130', 'CL', 'DS', 'O')
		THEN 'outpatient'
		WHEN AdmissionLevelofCare IN ('Hospital - Inpatient', 'I', 'INPATIENT', '101', '108', '129', 'Long Term Care')
		THEN 'inpatient'
		WHEN AdmissionLevelofCare IN ('ACUTE_INITIAL_LEVEL_OF_CARE_PENDING', 'Air Transportation', 'E', 'ER', 'Hospital - Emergency Medical', '103')
		THEN 'emergency'
		WHEN AdmissionLevelofCare IN ('Surgical')
		THEN 'surgical'
		WHEN AdmissionLevelofCare IN ('109', '114', '116')
		THEN 'unknown'
		ELSE null
	END AS level_of_care,
	coalesce(try_to_date(AdmissionDate, 'mm/dd/yyyy'), try_to_date(AdmissionDate)) as admit_date,
	AdmissionDiagnosis as dx_code,
	AdmissionDiagnosisDescription as dx_text,
	COALESCE(sfn.facility_name, cd.FacilityName) as facility,
	coalesce(try_to_date(DischargeDate, 'mm/dd/yyyy'), try_to_date(DischargeDate)) as discharge_date,
	split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
	'Devoted' as source,
	'sftp' as source_type,
from airbyte_source_prod.devoted.census_sftp cd
left join dw_prod.dw_staging.stg_sharepoint_suvida_facility_name sfn
	on cd.FacilityName = sfn.facility_code
	and sfn.code_source = 'Devoted'

union all

select
	ReportDate as report_date,
	DevotedID as source_member_id,
	PcpName as pcp,
	CASE
		WHEN AdmissionLevelofCare IN ('Skilled Nursing Care', 'SKILLED_NURSING')
		THEN 'skilled_nursing'
		WHEN AdmissionLevelofCare IN ('REHAB', 'Rehabilitation - Inpatient')
		THEN 'rehab'
		WHEN AdmissionLevelofCare IN ('OBS', 'OBSERVATION')
		THEN 'observation'
		WHEN AdmissionLevelofCare IN ('Hospital - Outpatient', 'OP', 'OUTPATIENT', '102', '104', '106', '130', 'CL', 'DS', 'O')
		THEN 'outpatient'
		WHEN AdmissionLevelofCare IN ('Hospital - Inpatient', 'I', 'INPATIENT', '101', '108', '129', 'Long Term Care')
		THEN 'inpatient'
		WHEN AdmissionLevelofCare IN ('ACUTE_INITIAL_LEVEL_OF_CARE_PENDING', 'Air Transportation', 'E', 'ER', 'Hospital - Emergency Medical', '103')
		THEN 'emergency'
		WHEN AdmissionLevelofCare IN ('Surgical')
		THEN 'surgical'
		WHEN AdmissionLevelofCare IN ('109', '114', '116')
		THEN 'unknown'
		ELSE null
	END AS level_of_care,
	AdmissionDate as admit_date,
	AdmissionDiagnosis as dx_code,
	AdmissionDiagnosisDescription as dx_text,
	COALESCE(sfn.facility_name, cd.FacilityName) as facility,
	DischargeDate as discharge_date,
	src_file_name,
	'Devoted' as source,
	'portal' as source_type,
from source_prod.devoted.src_devoted_census_portal cd
left join dw_dev.dev_jkizer_staging.stg_sharepoint_suvida_facility_name sfn
    on cd.FacilityName = sfn.facility_code
	and sfn.code_source = 'Devoted'