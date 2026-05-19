
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_coding_measure
    copy grants
    
    
    as (with coding_measure as (
	select
		member_id,
		measure_year,
		concat('HCC', measure_type) as hcc_category,
		measure_dx_code as icd_10_code,
		measure_status,
		measure_detail,
		report_date,
		measure_source,
		src_file_name,
		hcc_version::varchar as hcc_version,
	from dw_dev.dev_jkizer_staging.stg_devoted_coding_measure

	union all

	select
		member_id,
		measure_year,
		hcc_category,
		icd_10_code,
		measure_status,
		measure_detail,
		report_date,
		measure_source,
		src_file_name,
		hcc_version::varchar as hcc_version,
	from dw_dev.dev_jkizer_staging.stg_wellcare_coding_measure

	union all

	select
		member_id,
		measure_year,
		measure_type as hcc_category,
		measure_dx_code as icd_10_code,
		measure_status,
		measure_detail,
		report_date,
		measure_source,
		src_file_name,
		hcc_version::varchar as hcc_version,
	from dw_dev.dev_jkizer_staging.stg_wellmed_coding_measure

	union all

	select
		member_id,
		measure_year,
		measure_type as hcc_category,
		measure_dx_code as icd_10_code,
		measure_status,
		measure_detail,
		report_date,
		measure_source,
		src_file_name,
		hcc_version::varchar as hcc_version,
	from dw_dev.dev_jkizer_staging.stg_united_az_coding_measure
)
select
    member_id,
	to_varchar(floor(measure_year)) as measure_year,
	shr.hcc as hcc_category,
	shr.hcc_description,
	cm.hcc_version::varchar as hcc_version,
	cm.icd_10_code,
	iff(aicd.icd_10_code is not null, true, false) as is_acute_icd,
	lower(measure_status) as payer_measure_status,
	case
		when lower(measure_status) in ('closed', 'reported','assessed and diagnosed') then 'closed'
		when lower(measure_status) in ('open', 'pending', 'open_acute', 'not reported', 'severity_increase','assessed and unable to diagnose at this time','not assessed') then 'open'
		when lower(measure_status) in ('suspected', 'predicted from disease model') then 'suspect'
		else null
	end as measure_status,
	measure_detail,
	report_date,
    measure_source,
	src_file_name,
    row_number() over (partition by member_id, measure_year, hcc_category, cm.icd_10_code order by report_date asc) as coding_gap_member_measure_dx_idx
from coding_measure cm
inner join dw_dev.dev_jkizer_staging.stg_hcc_reference shr
	on cm.hcc_category = shr.hcc
	and cm.hcc_version::varchar = shr.hcc_version::varchar
left join dw_dev.dev_jkizer_source.map_acute_icd_10_code aicd
	on cm.icd_10_code = aicd.icd_10_code
    )
;


  