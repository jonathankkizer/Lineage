with data as (
	select 
		encounter_skey,
		suvida_id,
		patient_id,
		visit_note_name,
		encounter_date,
		encounter_datetime,
		provider_name,
		npi,
		source,
		visit_type,
		visit_type_status,
	from dw_dev.dev_jkizer.patient_encounter
		unpivot (visit_type_status for visit_type in (IS_AWV, IS_RD, IS_ULTRASOUND, IS_XRAY, IS_PCP, IS_MH, IS_PT, IS_PHARMACY, IS_GUIA, IS_RN))
)
select *
from data
where visit_type_status = 1