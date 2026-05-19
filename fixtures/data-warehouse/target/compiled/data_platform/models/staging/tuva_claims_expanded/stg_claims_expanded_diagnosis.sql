with claims_diagnosis as (
	select 
		data_source,
		claim_id, 
		claim_line_number, 
		diagnosis_position,
		trim(icd_10_code) as icd_10_code
	from suvida_tuva.claims_expanded.medical_claim_expanded
	unpivot (
		icd_10_code for diagnosis_position in (diagnosis_code_1, diagnosis_code_2, diagnosis_code_3, diagnosis_code_4, diagnosis_code_5, diagnosis_code_6, diagnosis_code_7, diagnosis_code_8, diagnosis_code_9, diagnosis_code_10, diagnosis_code_11, diagnosis_code_12, diagnosis_code_13, diagnosis_code_14, diagnosis_code_15, diagnosis_code_16, diagnosis_code_17, diagnosis_code_18, diagnosis_code_19, diagnosis_code_20, diagnosis_code_21, diagnosis_code_22, diagnosis_code_23, diagnosis_code_24, diagnosis_code_25)
	)
)
select
	*,
	'icd_10_code' as code_type,
from claims_diagnosis
where icd_10_code is not null