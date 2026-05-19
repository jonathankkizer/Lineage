
  
    

create or replace transient table dw_dev.dev_jkizer.patient_overall_high_risk_tag_status
    copy grants
    
    
    as (with current_tagged_patients as (
	select
		patient_id,
		tag_value
	from dw_dev.dev_jkizer_staging.stg_elation_patient_tag
	where
		tag_value in ('High-Risk') and
		deletion_datetime is null
),

patient_tag_status as (
	select
		ps.suvida_id,
		ps.elation_id,
		ps.is_active_assignment,
		case
			when lower(trim(ps.elation_status)) = 'deceased' then 1
			else 0
		end as is_deceased,
		ps.high_risk_patient,
		iff(tag_value is not null, 1, 0) as has_risk_level_tag,
		case
			when lower(trim(ps.elation_status)) = 'deceased' then 0
			when ps.high_risk_patient = 1 then 1
			else 0
		end as should_have_tag
	from dw_dev.dev_jkizer.patient_summary ps
	full outer join current_tagged_patients ctp on ps.elation_id = ctp.patient_id
)

select *
from patient_tag_status
where should_have_tag <> has_risk_level_tag
    )
;


  