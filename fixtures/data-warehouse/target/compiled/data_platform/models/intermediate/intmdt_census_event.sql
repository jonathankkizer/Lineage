with
-- Bamboo Health: reshape event-level ADT data to one row per visit
bamboo_health_census as (
	select
		patient_id as source_member_id,
		min(iff(status in ('Presented', 'Admitted'), status_date, null))
			over (partition by visit_id) as admit_date,
		max(iff(status = 'Discharged', status_date, null))
			over (partition by visit_id) as discharge_date,
		nullif(trim(concat(
			coalesce(attending_provider_first_name, ''),
			' ',
			coalesce(attending_provider_last_name, '')
		)), '') as attending_physician,
		case
			when setting = 'Emergency' then 'emergency'
			when facility_type = 'HHA' then 'outpatient'
			when facility_type = 'SNF' then 'skilled_nursing'
			when setting = 'Inpatient' then 'inpatient'
			else 'unknown'
		end as level_of_care,
		facility_name as facility,
		report_date,
		primary_diagnosis_code as dx_code,
		primary_diagnosis_description as dx_text,
		src_file_name,
		source,
		source_type,
		visit_id,
		status_date,
		event_processed_date
	from dw_dev.dev_jkizer_staging.stg_bamboo_health_census
	qualify row_number() over (partition by visit_id order by status_date desc, event_processed_date desc) = 1
),

-- Group A: sources with window partition (source_member_id, admit_date, facility)
-- Wellcare, United, Airtable, Alignment
group_a_deduped as (
	select distinct
		source_member_id, admit_date, source, attending_physician,
		discharge_date, level_of_care, facility, report_date,
		dx_code, dx_text, src_file_name, source_type
	from (
		select
			source_member_id, admit_date, source,
			null as attending_physician,
			discharge_date, level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from dw_dev.dev_jkizer_staging.stg_wellcare_census
		where admit_date <= dateadd(day, 60, current_date())

		union all

		select
			source_member_id, admit_date, source,
			attending_physician,
			discharge_date, level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from dw_dev.dev_jkizer_staging.stg_united_az_census
		where admit_date <= dateadd(day, 60, current_date())

		union all

		select
			source_member_id, admit_date, source,
			null as attending_physician,
			discharge_date, level_of_care,
			admit_facility as facility,
			to_date(created_datetime) as report_date,
			null as dx_code,
			null as dx_text,
			'Airtable Manual Entry' as src_file_name,
			source_type
		from dw_dev.dev_jkizer_staging.stg_airtable_census_manual_form
		where admit_date <= dateadd(day, 60, current_date())

		union all

		select
			source_member_id, admit_date, source,
			attending_physician,
			discharge_date, level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from dw_dev.dev_jkizer_staging.stg_alignment_census
		where admit_date <= dateadd(day, 60, current_date())
	)
),
group_a as (
	select
		*,
		min(report_date) over (partition by source, source_member_id, admit_date, facility) as earliest_report_date,
		max(report_date) over (partition by source, source_member_id, admit_date, facility) as max_report_date,
		row_number() over (partition by source, source_member_id, admit_date, facility order by report_date desc) as admission_order_desc,
		min(iff(discharge_date is not null, report_date, null)) over (partition by source, source_member_id, admit_date, facility) as earliest_discharge_report_date
	from group_a_deduped
),

-- Group B: sources with window partition (source_member_id, admit_date, facility, level_of_care)
-- Devoted, Wellmed, GHH, Bamboo Health
group_b_deduped as (
	select distinct
		source_member_id, admit_date, source, attending_physician,
		discharge_date, level_of_care, facility, report_date,
		dx_code, dx_text, src_file_name, source_type
	from (
		select
			source_member_id, admit_date, source,
			null as attending_physician,
			discharge_date, level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from dw_dev.dev_jkizer_staging.stg_devoted_census
		where admit_date <= dateadd(day, 60, current_date())

		union all

		select
			source_member_id, admit_date, source,
			null as attending_physician,
			try_to_date(to_varchar(discharge_date)) as discharge_date,
			level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from dw_dev.dev_jkizer_staging.stg_wellmed_census
		where admit_date <= dateadd(day, 60, current_date())

		union all

		select
			source_member_id, admit_date, source,
			coalesce(attending_physician, referring_physician) as attending_physician,
			discharge_date, level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from dw_dev.dev_jkizer_staging.stg_ghh_adt_census
		where admit_date <= dateadd(day, 60, current_date())

		union all

		select
			source_member_id, admit_date, source,
			attending_physician,
			discharge_date, level_of_care, facility, report_date,
			dx_code, dx_text, src_file_name, source_type
		from bamboo_health_census
		where admit_date <= dateadd(day, 60, current_date())
	)
),
group_b as (
	select
		*,
		min(report_date) over (partition by source, source_member_id, admit_date, facility, level_of_care) as earliest_report_date,
		max(report_date) over (partition by source, source_member_id, admit_date, facility, level_of_care) as max_report_date,
		row_number() over (partition by source, source_member_id, admit_date, facility, level_of_care order by report_date desc) as admission_order_desc,
		min(iff(discharge_date is not null, report_date, null)) over (partition by source, source_member_id, admit_date, facility, level_of_care) as earliest_discharge_report_date
	from group_b_deduped
),

-- Combine both groups and join suvida_id once
census_data as (
	select * from group_a
	union all
	select * from group_b
),
census_event as (
	select
		case
			when cd.source = 'Bamboo Health' then cd.source_member_id
			when cd.source = 'ghh_adt_census' then coalesce(siw.suvida_id, simew.suvida_id)
			else siw.suvida_id
		end as suvida_id,
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
		iff(cd.source in ('UHG/Wellmed','Devoted','Wellcare/Centene','United','Alignment AZ'), 1, 0) as payor_flag,
		iff(cd.source in ('ghh_adt_census', 'Bamboo Health'), 1, 0) as hie_flag,
		admission_order_desc
	from census_data cd
	left join (
		select distinct suvida_id, member_id, source
		from dw_dev.dev_jkizer.suvida_id_walk
	) siw
		on cd.source_member_id = siw.member_id
		and siw.source = iff(cd.source in ('ghh_adt_census', 'Airtable'), 'Elation', cd.source)
	left join (
		select elation_id, max(suvida_id) as suvida_id
		from dw_dev.dev_jkizer.suvida_id_master_elation_walk
		where source = 'Elation'
		and suvida_id is not null
		group by elation_id
	) simew
		on cd.source_member_id = simew.elation_id
		and cd.source = 'ghh_adt_census'
)

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