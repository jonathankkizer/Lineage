select
	md5(cast(coalesce(cast(uq_patient_tag as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_tag_skey,
	siw.suvida_id,
	pt.patient_id,
	tag_value,
	creation_datetime,
	deletion_datetime,
	iff(deletion_datetime is null, true, false) as is_active_tag,
	created_by_user_id as tag_created_by_user_id,
	deleted_by_user_id as tag_deleted_by_user_id,
from dw_dev.dev_jkizer_staging.stg_elation_patient_tag pt
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on pt.patient_id = siw.member_id
	and siw.source = 'Elation'
where tag_value != ''