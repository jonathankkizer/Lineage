select
	fqm.suvida_id,
	fqm.quality_measure,
	fqm.measure_source,
	fqm.measure_year,
	apc.quality_measure_skey,
	apc.benzo_med,
	apc.ach_med,
	apc.opioid_med,
	iff(opioid_med is not null or ach_med is not null or benzo_med is not null, true, false) as is_measure_documented,
	apc.last_modified_by_name,
	apc.last_modified_by_email,
	apc.last_modified_datetime,
	--apc.run_datetime,
	apc.workflow_status_index,
from dw_dev.dev_jkizer_staging.stg_airtable_med_adherence_pharm apc
left join dw_dev.dev_jkizer.fct_quality_measure fqm
	on apc.quality_measure_skey = fqm.quality_measure_skey
	and fqm.quality_measure_report_rank = 1