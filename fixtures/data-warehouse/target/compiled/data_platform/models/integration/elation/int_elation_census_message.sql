/* NOTE THAT THIS MODEL INTEGRATES WITH trigger_pl_prod_elation_health_adt_alerts_orchestrator and similar models to create Elation Messages; do not edit or alter without care */



with census_data as (
	select
		siw.suvida_id,
		wc.source_member_id,
		admit_date,
		wc.source,
		null as attending_physician,
		discharge_date,
		level_of_care,
		facility,
		report_date,
		dx_code,
		dx_text,
		src_file_name,
		min(report_date) over (partition by source_member_id, admit_date, facility) as earliest_report_date,
		max(report_date) over (partition by source_member_id, admit_date, facility) as max_report_date,
		row_number() over (partition by source_member_id, admit_date, facility order by report_date DESC) as admission_order_desc,
		min(iff(discharge_date is not null, report_date, null)) over (partition by source_member_id, admit_date, facility) as earliest_discharge_report_date,
		source_type,
	from dw_dev.dev_jkizer_staging.stg_wellcare_census wc
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on wc.source_member_id = siw.member_id
		and wc.source = siw.source
	where coalesce(admit_date, discharge_date) >= dateadd(day, -60, current_date())
	group by 1,2,3,4,5,6,7,8,9,10,11,12,17

	union all

	select
		siw.suvida_id,
		source_member_id,
		admit_date,
		dev.source,
		null as attending_physician,
		discharge_date,
		level_of_care,
		facility,
		report_date,
		dx_code,
		dx_text,
		src_file_name,
		min(report_date) over (partition by source_member_id, admit_date, facility, level_of_care) as earliest_report_date,
		max(report_date) over (partition by source_member_id, admit_date, facility, level_of_care) as max_report_date,
		row_number() over (partition by source_member_id, admit_date, facility, level_of_care order by report_date DESC) as admission_order_desc,
		min(iff(discharge_date is not null, report_date, null)) over (partition by source_member_id, admit_date, facility, level_of_care) as earliest_discharge_report_date,
		source_type,
	from dw_dev.dev_jkizer_staging.stg_devoted_census dev
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on dev.source_member_id = siw.member_id
		and dev.source = siw.source
	where coalesce(admit_date, discharge_date) >= dateadd(day, -60, current_date())
	group by 1,2,3,4,5,6,7,8,9,10,11,12,17

	union all

	select
		siw.suvida_id,
		wm.source_member_id,
		admit_date,
		wm.source,
		null as attending_physician,
		try_to_date(to_varchar(discharge_date)) as discharge_date,
		level_of_care,
		facility,
		report_date,
		dx_code,
		dx_text,
		src_file_name,
		min(report_date) over (partition by wm.source_member_id, admit_date, facility, level_of_care) as earliest_report_date,
		max(report_date) over (partition by wm.source_member_id, admit_date, facility, level_of_care) as max_report_date,
		row_number() over (partition by wm.source_member_id, admit_date, facility, level_of_care order by report_date DESC) as admission_order_desc,
		min(iff(try_to_date(to_varchar(discharge_date)) is not null, report_date, null)) over (partition by wm.source_member_id, admit_date, facility, level_of_care) as earliest_discharge_report_date,
		source_type,
	from dw_dev.dev_jkizer_staging.stg_wellmed_census wm
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on wm.source_member_id = siw.member_id
		and wm.source = siw.source
	where coalesce(admit_date, discharge_date) >= dateadd(day, -60, current_date())
	group by 1,2,3,4,5,6,7,8,9,10,11,12,17

	union all

	select
		coalesce(siw.suvida_id, simew.suvida_id) as suvida_id,
		source_member_id,
		admit_date,
		ghh.source,
		coalesce(attending_physician, referring_physician) as attending_physician,
		discharge_date,
		level_of_care,
		facility,
		report_date,
		dx_code,
		dx_text,
		src_file_name,
		min(report_date) over (partition by source_member_id, admit_date, facility, level_of_care) as earliest_report_date,
		max(report_date) over (partition by source_member_id, admit_date, facility, level_of_care) as max_report_date,
		row_number() over (partition by source_member_id, admit_date, facility, level_of_care order by report_date DESC) as admission_order_desc,
		min(iff(discharge_date is not null, report_date, null)) over (partition by source_member_id, admit_date, facility, level_of_care) as earliest_discharge_report_date,
		source_type,
	from dw_dev.dev_jkizer_staging.stg_ghh_adt_census ghh
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on ghh.source_member_id = siw.member_id
		and siw.source = 'Elation'
	left join dw_dev.dev_jkizer.suvida_id_master_elation_walk simew
		on ghh.source_member_id = simew.elation_id
		and simew.source = 'Elation'
	where coalesce(admit_date, discharge_date) >= dateadd(day, -60, current_date())
	group by 1,2,3,4,5,6,7,8,9,10,11,12,17

	union all

	select
		siw.suvida_id,
		source_member_id,
		admit_date,
		uaz.source,
		attending_physician,
		uaz.discharge_date,
		level_of_care,
		facility,
		report_date,
		dx_code,
		dx_text,
		src_file_name,
		min(report_date) over (partition by source_member_id, admit_date, facility) as earliest_report_date,
		max(report_date) over (partition by source_member_id, admit_date, facility) as max_report_date,
		row_number() over (partition by source_member_id, admit_date, facility order by report_date desc) as admission_order_desc,
		min(iff(discharge_date is not null, report_date, null)) over (partition by source_member_id, admit_date, facility) as earliest_discharge_report_date,
		source_type,
	from dw_dev.dev_jkizer_staging.stg_united_az_census uaz
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on uaz.source_member_id = siw.member_id
		and uaz.source = siw.source
	where coalesce(admit_date, discharge_date) >= dateadd(day, -60, current_date())
	group by 1,2,3,4,5,6,7,8,9,10,11,12,17

	union all

	select
		siw.suvida_id,
		source_member_id,
		admit_date,
		amf.source,
		null as attending_physician,
		amf.discharge_date,
		level_of_care,
		admit_facility as facility,
		to_date(created_datetime) as report_date,
		null as dx_code,
		null as dx_text,
		'Airtable Manual Entry' as src_file_name,
		min(to_date(created_datetime)) over (partition by source_member_id, admit_date, admit_facility) as earliest_report_date,
		max(to_date(created_datetime)) over (partition by source_member_id, admit_date, admit_facility) as max_report_date,
		row_number() over (partition by source_member_id, admit_date, admit_facility order by created_datetime desc) as admission_order_desc,
		min(iff(discharge_date is not null, to_date(created_datetime), null)) over (partition by source_member_id, admit_date, admit_facility) as earliest_discharge_report_date,
		source_type,
	from dw_dev.dev_jkizer_staging.stg_airtable_census_manual_form amf
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on amf.source_member_id = siw.member_id
		and siw.source = 'Elation'
	where coalesce(admit_date, discharge_date) >= dateadd(day, -60, current_date())
), census_event as (
	select
		cd.suvida_id,
		ifnull(cd.source_member_id, 'NULLID') as source_member_id,
		cd.admit_date,
		cd.source,
		cd.attending_physician,
		cd.discharge_date,
		earliest_report_date,
		earliest_discharge_report_date,
		max_report_date,
		level_of_care,
		facility,
		cd.report_date,
		dx_code,
		dx_text,
		src_file_name,
		source_type,
		iff(source in ('UHG/Wellmed','Devoted','Wellcare/Centene','United'), 1, 0) as payor_flag,
		iff(source = 'ghh_adt_census', 1, 0) as hie_flag,
		admission_order_desc
	from census_data cd
), intmdt_census_event as (
	select
		md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(source_member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(admit_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(discharge_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(level_of_care as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dx_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dx_text as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(facility as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(attending_physician as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(source as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as census_event_skey,
		suvida_id,
		source_member_id,
		admit_date,
		source,
		attending_physician,
		discharge_date,
		level_of_care,
		facility,
		report_date,
		earliest_report_date,
		earliest_discharge_report_date,
		max_report_date,
		dx_code,
		dx_text,
		payor_flag,
		hie_flag,
		src_file_name,
		source_type,
		admission_order_desc
	from census_event
	where admit_date <= dateadd(day, 60, current_date())
), aggregate_census_data as (
	select
		suvida_id,
		admit_date,
		level_of_care,
		facility,
		max(attending_physician) as attending_physician,
		max(discharge_date) as discharge_date,
		min(earliest_report_date) as earliest_report_date,
		min(earliest_discharge_report_date) as earliest_discharge_report_date,
		max(max_report_date) as max_report_date,
		min(dx_code) as dx_code,
		min(dx_text) as dx_text,
		max(payor_flag) as payor_flag,
		max(hie_flag) as hie_flag,
		listagg(distinct source,' | ') as data_sources,
		listagg(distinct source_type, ' | ') as data_source_types,
	from intmdt_census_event
	where suvida_id is not null and admission_order_desc = 1
	group by suvida_id, admit_date, level_of_care, facility
)
select
	md5(cast(coalesce(cast(acd.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(acd.admit_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(acd.level_of_care as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(acd.facility as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as census_event_id,
	acd.suvida_id,
	acd.admit_date,
	acd.level_of_care,
	acd.facility,
	acd.attending_physician,
	acd.discharge_date,
	acd.earliest_report_date,
	acd.earliest_discharge_report_date,
	acd.max_report_date,
	acd.dx_code,
	acd.dx_text,
	acd.payor_flag,
	acd.hie_flag,
	acd.data_sources,
	acd.data_source_types,
from aggregate_census_data acd