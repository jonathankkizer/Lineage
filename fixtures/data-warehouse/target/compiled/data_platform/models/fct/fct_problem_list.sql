with problem_list_base as (
	select
		siw.suvida_id,
		pp.patient_problem_id as problem_id,
		pp.problem_description,
		replace(ic.code, '.', '') as icd_10_code,
		ic.code as icd_10_code_with_decimal,
		ic.code_description as icd_10_code_description,
		pp.start_date,
		pp.last_modified_datetime,
		pp.deletion_datetime,
		iff(pp.deletion_datetime is null, false, true) as is_deleted,
		im.imo_code,
		ppc.icd10 as icd10_id,
		row_number() over (
			partition by siw.suvida_id, ic.code
			order by pp.start_date desc, pp.last_modified_datetime desc
		) as problem_recency_rank
	from dw_dev.dev_jkizer_staging.stg_elation_patient_problem pp
	inner join dw_dev.dev_jkizer_staging.stg_elation_patient_problem_code ppc
		on pp.patient_problem_id = ppc.patient_problem_id
		and ppc._idx = 1
	inner join dw_dev.dev_jkizer_staging.stg_elation_imo im
		on ppc.imo_code = im.imo_code
		and im.is_deleted = false
	inner join dw_dev.dev_jkizer_staging.stg_elation_icd10 ic
		on ppc.icd10 = ic.icd10_id
		and im.uq_id = ic.imo_id
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on pp.patient_id = siw.member_id
		and siw.source = 'Elation'
)
select
	md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(problem_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as problem_list_skey,
	suvida_id,
	problem_id,
	problem_description,
	icd_10_code,
	icd_10_code_with_decimal,
	icd_10_code_description,
	start_date,
	last_modified_datetime,
	deletion_datetime,
	is_deleted,
	imo_code,
	icd10_id,
	problem_recency_rank,
	iff(problem_recency_rank = 1, true, false) as is_most_recent_problem
from problem_list_base