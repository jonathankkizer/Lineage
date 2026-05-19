with current_tagged_patients as (
	select
		patient_id,
		tag_value
	from dw_dev.dev_jkizer_staging.stg_elation_patient_tag
	where
		tag_value in ('d-snp') and
		deletion_datetime is null
), d_snp_patients as (
	select
		suvida_id,
		elation_id,
		is_active_assignment,
		elation_status,
		case 
			when lower(trim(ps.elation_status)) = 'deceased' then 1
			else 0
		end as is_deceased,
		iff(payer_plan_name ilike '%d-snp%', 1, 0) as dsnp_patient,
	from dw_dev.dev_jkizer.patient_summary ps
	where payer_plan_name ilike '%d-snp%'
), patient_tag_status as (
	select
		ps.suvida_id,
		ps.elation_id,
		ps.is_active_assignment,
		ps.is_deceased,
		ps.dsnp_patient,
		iff(tag_value is not null, 1, 0) as has_dsnp_tag,
		case
			when lower(trim(ps.elation_status)) = 'deceased' then 0
			when dsnp_patient = 1 then 1
			else 0
		end as should_have_tag,
	from d_snp_patients ps
	full outer join current_tagged_patients ctp on ps.elation_id = ctp.patient_id
)

select *
from patient_tag_status
where should_have_tag <> has_dsnp_tag