with stage_one as (
    select 
        suvida_id, 
        'Diabetes Care - Blood Sugar Controlled' as quality_measure, 
        '1' as stage, 
        'Not Started' as stage_name, 
        'Open' as gap_status, 
        date(report_date) as evidence_date,
        quality_measure as evidence_desc,
        year(measure_year) as measure_year,
        object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Opened on ', to_varchar(report_date, 'MM/DD/YYYY')) 
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 0 
        and quality_measure = 'Diabetes Care - Blood Sugar Controlled'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)

, stage_two as (
    select 
        suvida_id, 
        'Diabetes Care - Blood Sugar Controlled' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed' as stage_name, 
        date(creation_date_time) as evidence_date, 
        order_test_name as evidence_desc, 
        year(creation_date_time) as measure_year,
        object_construct(
            'id', lab_order_id,
            'elation_object', 'Lab Order',
            'evidence_date', date(creation_date_time),
            'evidence_string', order_test_name,
            'evidence_description', concat('Order Placed for ',order_test_name, ' on ', to_varchar(creation_date_time, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_order
	where lower(order_test_name) like '%a1c%'
        and order_state != 'cancelled'
)

, stage_three_a as (
    select 
        suvida_id, 
        'Diabetes Care - Blood Sugar Controlled' as quality_measure , 
        '3' as stage, 
        'Open' as gap_status, 
        'Uncontrolled' as stage_name, 
        date(resulted_date) as evidence_date, 
        concat(test_name, ' ', coalesce(numeric_test_value, replace(test_value, '%', ''))) as evidence_desc, 
        year(resulted_date) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(resulted_date),
            'evidence_string', test_name,
            'evidence_numeric', coalesce(numeric_test_value, try_to_number(replace(test_value, '%', ''))),
            'evidence_description', concat('Uncontrolled (', coalesce(numeric_test_value, try_to_number(replace(test_value, '%', ''))), ') ',test_name, ' value on ',to_varchar(resulted_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_result
    where lower(test_name) like '%hemoglobin a1c%'
        and coalesce(numeric_test_value, try_to_number(replace(test_value, '%', ''))) > 9 
)

, stage_four as (
    select 
        suvida_id,
        year(encounter_date) as measure_year, 
        'Diabetes Care - Blood Sugar Controlled' as quality_measure,
        '4' as stage,
        'Pending' as gap_status,
        'Controlled' as stage_name,
        date(encounter_date) as evidence_date,
        cpt_code as evidence_desc,
        object_construct(
            'id', encounter_skey,
            'elation_object', 'Billing Code',
            'evidence_date', date(encounter_date),
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Controlled (CPT ',cpt_code,') on ',to_varchar(encounter_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array,
        row_number() over (
            partition by suvida_id, year(encounter_date)
            order by encounter_date desc, encounter_skey desc
        ) as rn
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('3044F', '3051F','3052F')
    qualify rn = 1
)

, stage_three_b as (
    select 
        lr.suvida_id,
        'Diabetes Care - Blood Sugar Controlled' as quality_measure,
        '3' as stage,
        'Pending' as gap_status,
        'Controlled - Missing CPT' as stage_name,
        date(lr.resulted_date) as evidence_date,
        concat(lr.test_name, ' ', coalesce(lr.numeric_test_value, try_to_number(replace(lr.test_value, '%', '')))) as evidence_desc,
        year(lr.resulted_date) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(resulted_date),
            'evidence_string', test_name,
            'evidence_numeric', coalesce(numeric_test_value, try_to_number(replace(test_value, '%', ''))),
            'evidence_description', concat('A1c Controlled (',coalesce(numeric_test_value, try_to_number(replace(test_value, '%', ''))), ') via test on ', to_varchar(resulted_date, 'MM/DD/YYYY'), ' but CPT code is missing')
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_result lr 
    left join stage_four sf
        on sf.suvida_id = lr.suvida_id
        and sf.measure_year = year(lr.resulted_date)
    where (
            lower(lr.test_name) like '%hemoglobin a1c%' or
            lower(lr.test_category) = 'hemoglobin a1c'
          )
        and coalesce(lr.numeric_test_value, try_to_number(regexp_replace(test_value, '[^0-9\.]', ''))) <= 9
        and sf.suvida_id is null
)

, combined_data as (
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_one
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_two
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_three_a
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_three_b
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_four
)

, tagged as (
    select distinct *,
        count(case when stage != '1' then 1 end) over (
            partition by suvida_id, measure_year
        ) as non_stage1_count
    from combined_data 
)

, with_stage_flags as (
    select *,
        max(case when stage in ('3', '4') then 1 else 0 end) over (
            partition by suvida_id, measure_year
        ) as has_stage_3_or_4
    from tagged
)

, ranked as (
    select *,
        row_number() over (
            partition by suvida_id, measure_year
            order by 
                case 
                    when has_stage_3_or_4 = 1 and stage not in ('3', '4') then 999
                    when stage_name = 'Payer Closed' then 1
                    else 2
                end,
                date(evidence_date) desc,
                cast(stage as int) desc
        ) as latest_rank_overall
    from with_stage_flags
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