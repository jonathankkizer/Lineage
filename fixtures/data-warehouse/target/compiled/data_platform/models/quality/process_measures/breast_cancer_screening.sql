with stage_one as (
    select 
        suvida_id,
        quality_measure,
        '1' as stage,
        'Not Started' as stage_name,
        'Open' as gap_status,
        date(report_date) as evidence_date,
        year(measure_year) as measure_year,
        quality_measure as evidence_desc,
        object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', to_varchar(report_date, 'MM/DD/YYYY'), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Opened on ', to_varchar(report_date, 'MM/DD/YYYY')) 
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 0 
      and quality_measure = 'Breast Cancer Screening'
      and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)

, stage_two_a as (
    select 
        suvida_id, 
        date(creation_date) as evidence_date, 
        'Breast Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed' as stage_name, 
        test_name as evidence_desc,
        year(creation_date_time) as measure_year,
        object_construct(
            'id', order_id,
            'elation_object', 'Letter',
            'evidence_date', to_varchar(creation_date, 'MM/DD/YYYY'), 
            'evidence_string', test_name,
            'evidence_description', concat('Mammogram Ordered on ', to_varchar(creation_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_misc_orders
    where (
            test_name ilike '%mammography%' or 
            test_name ilike '%mammo%'
          ) 
        and resolution_state != 'cancelled'
)

, stage_two_b as (
    select 
        suvida_id,
        quality_measure,
        '2' as stage,
        'Open' as gap_status,
        'Records Requested' as stage_name,
        date(last_modified_datetime) as evidence_date,
        year(measure_year) as measure_year,
        workflow_note as evidence_desc,
        object_construct(
            'id', quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', to_varchar(last_modified_datetime, 'MM/DD/YYYY'), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Records Requested on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY')) 
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Breast Cancer Screening'
        and workflow_status_detail = 'Requested Record'
        and workflow_status_index = 1
        and is_automated_activity = false
)

, stage_two_c as (
    select 
        suvida_id, 
        'Breast Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Mammogram in Record - Check Dates' as stage_name,
        case 
            when count(distinct case when is_mammo_bilateral = 1 then 1 end) > 0
                then max(case when is_mammo_bilateral = 1 then document_tag_values end)
            else listagg(document_tag_values, ' * ') within group (order by document_tag_values)
        end as evidence_desc, 
        date(max(document_date)) as evidence_date, 
        year('2025-12-31'::date) as measure_year,
        object_construct(
            'id', max(report_id),
            'elation_object', 'Report',
            'evidence_date', to_varchar(max(document_date), 'MM/DD/YYYY'),
            'evidence_string', case 
                    when count(distinct case when is_mammo_bilateral = 1 then 1 end) > 0
                    then max(case when is_mammo_bilateral = 1 then document_tag_values end)
                    else listagg(document_tag_values, ' * ') within group (order by document_tag_values)
                    end,
            'evidence_description', concat('Mammogram present in old records from ',to_varchar(max(document_date), 'MM/DD/YYYY'), ': ',max(report_title))
            ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_elation_report
    where (is_mammo_bilateral = 1
            or lower(document_tag_values) like '%mammogram: unilateral result left (suvida)%'
            or lower(document_tag_values) like '%mammogram: unilateral result right (suvida)%'
        ) and 
        (
            num_doc_tags > 1 or
            report_type = 'OldRecord' or 
            lower(report_title) like '%past record%' or
            lower(report_title) like '%expired%' and 
            lower(report_title) like '%sample not processed%' 
        ) and
        document_date >= date_from_parts(year('2025-12-31'::date) - 2, 10, 1) 
    group by suvida_id
    having 
        count(distinct case when is_mammo_bilateral = 1 then 1 end) > 0
        or (
            count(distinct case when lower(document_tag_values) like '%mammogram: unilateral result left (suvida)%' then 1 end) > 0
            and count(distinct case when lower(document_tag_values) like '%mammogram: unilateral result right (suvida)%' then 1 end) > 0
            and count(distinct case when is_mammo_bilateral = 1 then 1 end) = 0
        )
)

, stage_three_a as (
    select 
        suvida_id, 
        'Breast Cancer Screening' as quality_measure, 
        '3' as stage, 
        'Open' as gap_status, 
        'Exclusion Identified' as stage_name, 
        date(max(diagnosis_date)) as evidence_date,
        listagg(icd_10_code_description, ' | ') within group (order by icd_10_code) as evidence_desc,
        year(diagnosis_date) as measure_year,
        object_construct(
            'id', max(visit_note_id),
            'elation_object', 'Bill',
            'evidence_date', to_varchar(max(diagnosis_date), 'MM/DD/YYYY'),
            'evidence_string', listagg(icd_10_code_description, ' | ') within group (order by icd_10_code),
            'evidence_description', concat('Exclusion Identified on ',to_varchar(max(diagnosis_date), 'MM/DD/YYYY'), ': ', listagg(icd_10_code_description, ' | ') within group (order by icd_10_code))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_diagnosis
	where source_type = 'emr' and
        (
            icd_10_code like '%Z9013%'
            or icd_10_code in ('0HTU0ZZ','0HTT0ZZ')
        ) and
        year(diagnosis_date) = year('2025-12-31'::date)
    group by suvida_id, year(diagnosis_date)
)

, stage_three_b as (
    select
        suvida_id, 
        'Breast Cancer Screening' as quality_measure, 
        '3' as stage, 
        'Open' as gap_status, 
        'Guia Engaged' as stage_name, 
        concat(care_flow_name,' ',object_name,' ',track_name,' ',action_name,' ', care_flow_status) as evidence_desc, 
        date(activity_date) as evidence_date, 
        year(activity_date) as measure_year,
        object_construct(
            'id', activity_id,
            'suvida_object', 'patient_awell_care_flows',
            'evidence_date', to_varchar(activity_date, 'MM/DD/YYYY'),
            'evidence_string', concat(care_flow_name,' ',object_name,' ',track_name,' ',action_name),
            'evidence_description', concat('Guia Engaged on ',to_varchar(activity_date, 'MM/DD/YYYY'))
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.patient_awell_care_flows
    where care_flow_name = 'Guia Quality Gap Assistance' and 
    care_flow_status = 'completed' and
        (
            object_name = 'Outreach - Breast Cancer Screening' or
            lower(track_name) like '%breast%' or 
            lower(action_name) like '%breast%' 
        )
    qualify row_number() over (
        partition by suvida_id 
        order by activity_date desc
        ) = 1 
)

, stage_four as (
    select 
        suvida_id, 
        'Breast Cancer Screening' as quality_measure, 
        '4' as stage, 
        'Closed' as gap_status, 
        'Suvida Closed' as stage_name,
        listagg(document_tag_values, ' * ') within group (order by document_tag_values) as evidence_desc, 
        date(max(document_date)) as evidence_date, 
        year('2025-12-31'::date) as measure_year,
        object_construct(
            'id', max(report_id),
            'elation_object', 'Report',
            'evidence_date', to_varchar(max(document_date), 'MM/DD/YYYY'),
            'evidence_string', listagg(document_tag_values, ' * ') within group (order by document_tag_values),
            'evidence_description', concat('Suvida closed on ',to_varchar(max(document_date), 'MM/DD/YYYY'),': ', max(report_title))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_elation_report
    where (is_mammo_bilateral = 1
            or document_tag_values = 'Mammogram: Unilateral Result Left (Suvida)'
            or document_tag_values = 'Mammogram: Unilateral Result Right (Suvida)'
        ) and 
        num_doc_tags = 1 and  
        report_type != 'OldRecord' and 
        lower(report_title) not like '%past record%' and
        lower(report_title) not like '%expired%' and 
        lower(report_title) not like '%sample not processed%' and
        document_date >= date_from_parts(year('2025-12-31'::date) - 2, 10, 1) 
    group by suvida_id
    having 
        count(distinct case when is_mammo_bilateral = 1 then 1 end) > 0
        or (
            count(distinct case when document_tag_values = 'Mammogram: Unilateral Result Left (Suvida)' then 1 end) > 0
            and count(distinct case when document_tag_values = 'Mammogram: Unilateral Result Right (Suvida)' then 1 end) > 0
            and count(distinct case when is_mammo_bilateral = 1 then 1 end) = 0
        )
)

, stage_five as (
    select 
        suvida_id, 
        date(last_modified_datetime) as evidence_date, 
        'Breast Cancer Screening' as quality_measure, 
        '5' as stage, 
        'Pending' as gap_status, 
        'Supplemental Data Submitted' as stage_name, 
        quality_measure as evidence_desc, 
        year(last_modified_datetime) as measure_year,
        object_construct(
            'id', quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', to_varchar(last_modified_datetime, 'MM/DD/YYYY'), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.workflow_quality_stars
    where workflow_status_detail = 'Submitted - Pending Payer Audit'
        and quality_measure = 'Breast Cancer Screening'
        and is_automated_activity = false
)

, stage_six as (
    select 
        suvida_id, 
        'Breast Cancer Screening' as quality_measure, 
        '6' as stage, 
        'Closed' as gap_status, 
        'Payer Closed' as stage_name, 
        measure_source as evidence_desc, 
        date(report_date) as evidence_date, 
        year(measure_year) as measure_year,
        object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', to_varchar(report_date, 'MM/DD/YYYY'), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 1
        and quality_measure = 'Breast Cancer Screening'
        and measure_year_report_rank = 1
)

, combined_data as (
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_one
    union all 
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_a
    union all 
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_b
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_c
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_a
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_b
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_four
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_five
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_six
)

, tagged as (
    select distinct * ,
        count(case when stage != '1' then 1 end) over (
            partition by suvida_id, measure_year
        ) as non_stage1_count
    from combined_data
)

, ranked as (
    select * ,
        row_number() over (
            partition by suvida_id, measure_year
            order by 
                case when stage != '1' and stage_name = 'Payer Closed' then 1
                     when stage != '1' then 2
                     else 999
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