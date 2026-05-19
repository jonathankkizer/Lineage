
  
    

create or replace transient table dw_dev.dev_jkizer.fct_clinical_score
    copy grants
    
    
    as (select 
	suvida_id,
	patient_id,
	form_name,
	case
		when form_name = 'MINI-COG' then 'Mini-Cog'
		when form_name = 'GAD-7 Questionnaire' then 'GAD-7'
		when form_name = 'PHQ-9 Questionnaire' then 'PHQ-9'
		when form_name = 'PHQ-2 Questionnaire' then 'PHQ-2'
		when form_name = 'AUDIT-C Questionnaire' then 'Alcohol use'
		when form_name = 'Activities of Daily Living' then 'KATZ-ADL'
	end as history_form_name,
	form_category,
	clinical_form_question,
	answer,
	answer_type,
	date(creation_time) as creation_date,
	creation_time as creation_date_time,
	created_by_user_id,
	row_number() over (partition by suvida_id, form_name order by creation_time desc) as clinical_form_index, -- 1 = most recent score per form per patient
from dw_dev.dev_jkizer_staging.stg_elation_clinical_form_collection cfc
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on cfc.patient_id = siw.member_id
	and siw.source = 'Elation'
where answer_type = 'total_score' -- only pulling cumulative score
and is_deleted = false -- removing deleted values
    )
;


  