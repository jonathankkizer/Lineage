
  
    

create or replace transient table dw_dev.dev_jkizer_quality.zephyr
    copy grants
    
    
    as (with stage_one as (
	select
		year(measure_year) as measure_year,
		suvida_id,
		quality_measure,
		'1' as stage,
		'Open' as gap_status,
		'Not Started' as stage_name,
		report_date as evidence_date,
		quality_measure as evidence_desc,
		object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Opened on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
	from dw_dev.dev_jkizer.fct_quality_measure
	where measure_numerator = 0 
		and quality_measure = 'Zephyr'
		and measure_year_report_rank = 1
	qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)
, stage_two as (
	select 
		year(measure_year) as measure_year,
		suvida_id, 
		'Zephyr' as quality_measure,
		'2' as stage,
		'Pending' as gap_status,
		'Supplemental Data Submitted' as stage_name,
		last_modified_datetime as evidence_date,
		workflow_status_detail as evidence_desc,
		object_construct(
            'id', quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', date(last_modified_datetime), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
	from dw_dev.dev_jkizer.workflow_quality_stars
	where quality_measure = 'Zephyr'
		and workflow_status_detail = 'Submitted - Pending Payer Audit'
		and workflow_status_index = 1
		and is_automated_activity = false
)
, stage_three as (
	select 
		year(measure_year) as measure_year, 
		suvida_id, 
		quality_measure, 
		'3' as stage, 
		'Closed' as gap_status, 
		'Payer Closed' as stage_name, 
		report_date as evidence_date,
		measure_source as evidence_desc,
		object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
	from dw_dev.dev_jkizer.fct_quality_measure
	where measure_numerator = 1 
		and quality_measure = 'Zephyr'
		and measure_year_report_rank = 1
	qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)
, combined_data as (
	select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
	from stage_one
	union all
	select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
	from stage_two
	union all
	select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
	from stage_three
)
, tagged as (
	select distinct *,
		count(case when stage != '1' then 1 end) over (
			partition by suvida_id, measure_year
		) as non_stage1_count
	from combined_data 
)
, ranked as (
	select *,
		row_number() over (
			partition by suvida_id, measure_year
			order by 
				case when stage != '1' and stage_name = 'Payer Closed' then 1
					 when stage != '1' then 2
					 else 999 -- stage 1 pushed to end
				end,
				cast(stage as int) desc
		) as latest_rank_overall
	from tagged
)
select distinct
	suvida_id,
	measure_year,
	quality_measure,
	stage,
	stage_name,
	gap_status,
	evidence_date,
	evidence_desc,
	latest_rank_overall,
	quality_engine_info_array
from ranked
    )
;


  