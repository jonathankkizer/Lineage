select 
	c.claim_id, 
	c.patient_id, 
	mc.member_id, 
	c.recorded_date as condition_date, 
	c.condition_type, 
	c.normalized_code_type as code_type, 
	c.normalized_code as code, 
	row_number() over (partition by c.patient_id, mc.member_id, c.normalized_code order by c.recorded_date desc) as diagnosis_rank,
	c.present_on_admit_code, 
	c.data_source, 
	c.tuva_last_run as last_update
from dw_dev.dev_jkizer_staging.stg_tuva_condition c
inner join dw_dev.dev_jkizer.intmdt_medical_claim mc
	on c.claim_id = mc.claim_id
qualify row_number() over (partition by c.claim_id order by mc.claim_line_number asc) = 1