
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_coding_pre_visit_review
  
  copy grants
  
  
  as (
    select
	appointment_skey,
	airtable_id,
	to_timestamp(run_datetime) as run_datetime,
	convert_timezone('UTC', 'America/Chicago', to_timestamp(created)) as created_datetime,
	assigned_coder,
	"Review Status" as review_status,
	elation_patient_url,
	split(elation_patient_url, '/')[4]::varchar as elation_id,
	"LAST MODIFIED BY" as last_modified_by,
	"LAST MODIFIED BY":email::varchar as last_modified_by_email,
	"LAST MODIFIED BY":name::varchar as last_modified_by_name,
	convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
	upper(replace("SUSPECT ICD 1", '.', '')) as suspect_icd_1,
	trim("SUSPECT ICD 1 EVIDENCE") as suspect_evidence_icd_1,
	upper(replace("SUSPECT ICD 2", '.', '')) as suspect_icd_2,
	trim("SUSPECT ICD 2 EVIDENCE") as suspect_evidence_icd_2,
	upper(replace("SUSPECT ICD 3", '.', '')) as suspect_icd_3,
	trim("SUSPECT ICD 3 EVIDENCE") as suspect_evidence_icd_3,
	upper(replace("SUSPECT ICD 4", '.', '')) as suspect_icd_4,
	trim("SUSPECT ICD 4 EVIDENCE") as suspect_evidence_icd_4,
	upper(replace("SUSPECT ICD 5", '.', '')) as suspect_icd_5,
	trim("SUSPECT ICD 5 EVIDENCE") as suspect_evidence_icd_5,
	upper(replace("SUSPECT ICD 6", '.', '')) as suspect_icd_6,
	trim("SUSPECT ICD 6 EVIDENCE") as suspect_evidence_icd_6,
	upper(replace("SUSPECT ICD 7", '.', '')) as suspect_icd_7,
	trim("SUSPECT ICD 7 EVIDENCE") as suspect_evidence_icd_7,
	upper(replace("SUSPECT ICD 8", '.', '')) as suspect_icd_8,
	trim("SUSPECT ICD 8 EVIDENCE") as suspect_evidence_icd_8,
	upper(replace("SUSPECT ICD 9", '.', '')) as suspect_icd_9,
	trim("SUSPECT ICD 9 EVIDENCE") as suspect_evidence_icd_9,
	upper(replace("SUSPECT ICD 10", '.', '')) as suspect_icd_10,
	trim("SUSPECT ICD 10 EVIDENCE") as suspect_evidence_icd_10,
	upper(replace("SUSPECT ICD 11", '.', '')) as suspect_icd_11,
	trim("SUSPECT ICD 11 EVIDENCE") as suspect_evidence_icd_11,
	upper(replace("SUSPECT ICD 12", '.', '')) as suspect_icd_12,
	trim("SUSPECT ICD 12 EVIDENCE") as suspect_evidence_icd_12,
	upper(replace("SUSPECT ICD 13", '.', '')) as suspect_icd_13,
	trim("SUSPECT ICD 13 EVIDENCE") as suspect_evidence_icd_13,
	upper(replace("SUSPECT ICD 14", '.', '')) as suspect_icd_14,
	trim("SUSPECT ICD 14 EVIDENCE") as suspect_evidence_icd_14,
	upper(replace("SUSPECT ICD 15", '.', '')) as suspect_icd_15,
	trim("SUSPECT ICD 15 EVIDENCE") as suspect_evidence_icd_15,
from source_prod.airtable.src_airtable_coding_pre_visit
where lower("LAST MODIFIED BY":"email"::string) != 'jkizer@suvidahealthcare.com' -- filter out items that this account touched, as updates/loads are done from here and don't count towards work completed
  );

