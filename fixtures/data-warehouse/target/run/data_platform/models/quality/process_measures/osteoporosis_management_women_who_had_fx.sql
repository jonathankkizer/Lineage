
  
    

create or replace transient table dw_dev.dev_jkizer_quality.osteoporosis_management_women_who_had_fx
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
        and quality_measure = 'Osteoporosis Management Women who had Fx'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)
, stage_two_a as (
    select 
        year(creation_date_time) as measure_year,
        suvida_id, 
        'Osteoporosis Management Women who had Fx' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed' as stage_name, 
        creation_date as evidence_date, 
        test_name as evidence_desc,
        object_construct(
            'id', order_id,
            'elation_object', 'Letter',
            'evidence_date', date(creation_date), 
            'evidence_string', test_name,
            'evidence_description', concat(test_name,' ordered on ', to_varchar(creation_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_misc_orders
    where lower(test_name) like '%dexa%' or 
        lower(test_name) like '%osteoporosis%' or
        lower(test_name) like '%bone mass%'
)
, stage_two_b as (
    select 
        year(signed_datetime) as measure_year,
        suvida_id, 
        'Osteoporosis Management Women who had Fx' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Prescription Sent' as stage_name, 
        signed_datetime as evidence_date,
        displayed_medication_name as evidence_desc,
        object_construct(
            'id', med_order_fill_id,
            'elation_object', 'Medication Order Template',
            'evidence_date', date(signed_datetime), 
            'evidence_string', displayed_medication_name,
            'evidence_description', concat(displayed_medication_name,' sent on ', to_varchar(signed_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.patient_med_order_fill
    where lower(displayed_medication_name) like '%romosozumab%' or 
        lower(displayed_medication_name) like '%abaloparatide%' or
        lower(displayed_medication_name) like '%alendronate%' or
        lower(displayed_medication_name) like '%ibandronate%' or 
        lower(displayed_medication_name) like '%risedronate%' or
        lower(displayed_medication_name) like '%zoledronic%' or 
        lower(displayed_medication_name) like '%abaloparatide%' or 
        lower(displayed_medication_name) like '%denosumab%' or 
        lower(displayed_medication_name) like '%raloxifene%' or 
        lower(displayed_medication_name) like '%romosozumab%' or 
        lower(displayed_medication_name) like '%teriparatide%'
)
, fracture_date as (
    select
        suvida_id,
        last_modified_datetime,
        osteo_fracture_date as fracture_date
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Osteoporosis Management Women who had Fx'
        and workflow_status_index = 1
)
, stage_three_a as (
    select
        year(dr.document_date) as measure_year,
        dr.suvida_id,
        'Osteoporosis Management Women who had Fx' as quality_measure, 
        '3' as stage, 
        'Pending' as gap_status, 
        'DEXA Complete' as stage_name, 
        concat('Fracture Date: ',fd.fracture_date,' DEXA Completion Date: ', dr.document_date) as evidence_desc,
        dr.document_date as evidence_date,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(dr.document_date),
            'evidence_fracture_date', date(fd.fracture_date),
            'evidence_description', concat('Dexa completed on ', to_varchar(dr.document_date, 'MM/DD/YYYY'), '. Fracture date on ', to_varchar(to_date(fd.fracture_date), 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from fracture_date fd
    join dw_dev.dev_jkizer.fct_elation_report dr
        on dr.suvida_id = fd.suvida_id
        and (lower(dr.report_title) like '%dexa%' or lower(dr.report_title) like '%bone mass%')
        and dr.document_date between fd.fracture_date
        and dateadd(month, 6, fd.fracture_date)
)
, stage_three_b as (
    select
        year(dr.document_date) as measure_year,
        dr.suvida_id,
        'Osteoporosis Management Women who had Fx' as quality_measure, 
        '3' as stage, 
        'Open' as gap_status, 
        'Past Deadline - Evidence Found' as stage_name, 
        concat('Fracture Date: ',fd.fracture_date,' DEXA Completion Date: ',dr.document_date) as evidence_desc,
        dr.document_date as evidence_date,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(dr.document_date),
            'evidence_fracture_date', date(fd.fracture_date),
            'evidence_description', concat('DEXA completed on ', to_varchar(dr.document_date, 'MM/DD/YYYY'), '. Fracture date on ', to_varchar(to_date(fd.fracture_date), 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from fracture_date fd
    join dw_dev.dev_jkizer.fct_elation_report dr
        on dr.suvida_id = fd.suvida_id
        and (lower(dr.report_title) like '%dexa%' or lower(dr.report_title) like '%bone mass%')
        and dr.document_date > dateadd(month, 6, fd.fracture_date)
    order by dr.suvida_id, dr.document_date
)
, stage_three_c as (
    select 
        year(m.last_fill_date) as measure_year,
        m.suvida_id, 
        'Osteoporosis Management Women who had Fx' as quality_measure, 
        '3' as stage, 
        'Pending' as gap_status, 
        'Prescription Filled' as stage_name, 
        m.last_fill_date as evidence_date,
        m.displayed_medication_name as evidence_desc,
        object_construct(
            'id', med_order_fill_id,
            'elation_object', 'Medication Order Template',
            'evidence_date', date(m.last_fill_date), 
            'evidence_string', displayed_medication_name,
            'evidence_description', concat(displayed_medication_name,' last filled on: ', to_varchar(last_fill_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from fracture_date f
    join dw_dev.dev_jkizer.patient_med_order_fill m on m.suvida_id = f.suvida_id
        and m.last_fill_date between f.fracture_date
        and DATEADD(month, 6, f.fracture_date)
    where lower(displayed_medication_name) like '%romosozumab%' or 
        lower(displayed_medication_name) like '%abaloparatide%' or
        lower(displayed_medication_name) like '%alendronate%' or
        lower(displayed_medication_name) like '%ibandronate%' or 
        lower(displayed_medication_name) like '%risedronate%' or
        lower(displayed_medication_name) like '%zoledronic%' or 
        lower(displayed_medication_name) like '%abaloparatide%' or 
        lower(displayed_medication_name) like '%denosumab%' or 
        lower(displayed_medication_name) like '%raloxifene%' or 
        lower(displayed_medication_name) like '%romosozumab%' or 
        lower(displayed_medication_name) like '%teriparatide%'
)
, stage_four as (
    select 
        year(last_modified_datetime) as measure_year,
        suvida_id,
        quality_measure,
        '4' as stage,
        'Pending' as gap_status,
        'Supplemental Data Submitted' as stage_name,
        workflow_status_detail as evidence_desc,
        last_modified_datetime as evidence_date,
        object_construct(
            'id', quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', date(last_modified_datetime), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Osteoporosis Management Women who had Fx'
        and workflow_status_detail = 'Submitted - Pending Payer Audit'
        and workflow_status_index = 1
)
, stage_five as (
   select 
        year(measure_year) as measure_year, 
        suvida_id, 
        quality_measure, 
        '5' as stage, 
        'Closed' as gap_status, 
        'Payer Closed' as stage_name, 
        measure_source as evidence_desc, 
        report_date as evidence_date,
        object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 1 
        and quality_measure = 'Osteoporosis Management Women who had Fx'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)
, stage_three_d as (
    select
        year('2025-12-31'::date) as measure_year,
        fd.suvida_id,
        'Osteoporosis Management Women who had Fx' as quality_measure, 
        '3' as stage, 
        'Open' as gap_status, 
        'Past Deadline - No Evidence Found' as stage_name, 
        concat('Fracture Date: ',fd.fracture_date) as evidence_desc,
        fd.fracture_date as evidence_date,
        object_construct(
            'id', null,
            'elation_object', 'N/A',
            'evidence_date', date(fd.fracture_date),
            'evidence_description', concat('No evidence found by deadline. Fracture date on ', to_varchar(to_date(fd.fracture_date), 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from fracture_date fd
    where '2025-12-31'::date > dateadd(month, 6, fd.fracture_date)
        and not exists (
            select 1
            from stage_five sf
            where sf.suvida_id = fd.suvida_id
        )
)
, combined_data as (
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_one
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_two_a
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_two_b
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_three_a
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_three_b
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_three_c
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_three_d
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_four
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_five
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
                cast(stage as int) desc,
                evidence_date desc
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


  