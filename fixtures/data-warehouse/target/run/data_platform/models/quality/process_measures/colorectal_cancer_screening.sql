
  
    

create or replace transient table dw_dev.dev_jkizer_quality.colorectal_cancer_screening
    copy grants
    
    
    as (with stage_one as (
    select 
        suvida_id, 
        date(report_date) as evidence_date, 
        quality_measure, 
        '1' as stage, 
        'Open' as gap_status, 
        'Not Started' as stage_name, 
        quality_measure as evidence_desc, 
        year(measure_year) as measure_year,
        object_construct(
            'id',quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Opened on ', to_varchar(report_date, 'MM/DD/YYYY')) 
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 0 
        and quality_measure = 'Colorectal Cancer Screening'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)

, stage_two_a as (
    select 
        suvida_id, 
        date(creation_date_time) as evidence_date, 
        'Colorectal Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed - FIT' as stage_name, 
        order_test_name as evidence_desc, 
        year(creation_date_time) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Lab Order',
            'evidence_date', date(creation_date_time),
            'evidence_string', order_test_name,
            'evidence_description', concat('Order Placed for FIT on ', to_varchar(creation_date_time, 'MM/DD/YYYY') )
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_order
	where (lower(order_test_name) like '%colofit%' 
        or lower(order_test_name) like '%fit%')
        and order_state != 'cancelled'
)

, stage_two_b as (
    select 
        suvida_id, 
        date(creation_date_time) as evidence_date, 
        'Colorectal Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed - iFOB' as stage_name, 
        order_test_name as evidence_desc, 
        year(creation_date_time) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Lab Order',
            'evidence_date', date(creation_date_time),
            'evidence_string', order_test_name,
            'evidence_description', concat('Order Placed for iFOB on ', to_varchar(creation_date_time, 'MM/DD/YYYY') )
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_order
	where (lower(order_test_name) like '%ifob%'
        or lower(order_test_name) like '%fecal%')
        and order_state != 'cancelled'
)

, stage_two_c as (
    select 
        suvida_id, 
        date(creation_date_time) as evidence_date, 
        'Colorectal Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed - Cologuard' as stage_name, 
        order_test_name as evidence_desc, 
        year(creation_date_time) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Lab Order',
            'evidence_date', date(creation_date_time),
            'evidence_string', order_test_name,
            'evidence_description', concat('Order Placed for Cologuard on ', to_varchar(creation_date_time, 'MM/DD/YYYY') )
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_order
	where lower(order_test_name) like '%cologuard%'
        and order_state != 'cancelled'
)

, stage_two_d as (
    select 
        suvida_id, 
        referral_body_text as evidence_desc, 
        date(last_modified_datetime) as evidence_date, 
        'Colorectal Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Referral Placed' as stage_name, 
        year(creation_datetime) as measure_year, 
        object_construct(
            'id', referral_id,
            'elation_object', 'Letter',
            'evidence_date', date(last_modified_datetime),
            'evidence_string', referral_body_text,
            'evidence_description', concat('Referall placed for Colonoscopy/Colon Cancer screening on ',to_varchar(last_modified_datetime, 'MM/DD/YYYY') )
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_referral
    where lower(referral_body_text) like '%colon cancer screening%'
        and resolution_state = 'outstanding' 
)

, stage_two_e as (
    select 
        suvida_id, 
        concat('Workflow Note: ',workflow_note, CHAR(10),'Workflow Status Detail: ', workflow_status_detail, char(10),' Workflow Attachment: ', workflow_attachment) as evidence_desc, 
        date(last_modified_datetime) as evidence_date,
        'Colorectal Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Records Requested' as stage_name, 
        year(last_modified_datetime) as measure_year,
        object_construct(
            'id',quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', date(last_modified_datetime), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Records Requested on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY') )
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Colorectal Cancer Screening'
        and workflow_status_detail = 'Requested Record'
        and workflow_status_index = 1
        and is_automated_activity = false
)

, stage_two_f as (
    select 
        suvida_id, 
        'Colorectal Cancer Screening' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Colo in Record - Check Dates' as stage_name,
        document_tag_values as evidence_desc,
        date(document_date) as evidence_date, 
        year(document_date) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(document_date),
            'evidence_string', document_tag_values,
            'evidence_description', concat('Screening present in old records from ',to_varchar(document_date, 'MM/DD/YYYY') ,': ',report_title)
        ) as quality_engine_info_array,
        row_number() over (
            partition by suvida_id 
            order by document_date desc, report_id desc
        ) as rn
    from dw_dev.dev_jkizer.fct_elation_report
    where (
            num_doc_tags > 1 
            or report_type = 'OldRecord' 
            or lower(report_title) like '%past record%'
          )
      and lower(report_title) not like '%expired%'
      and lower(report_title) not like '%sample not processed%'
      and (
          (
            (is_ifobt_negative = 1 or is_ifobt_positive = 1 or is_fit_dna_positive = 1 or is_fit_dna_negative = 1)
            and creation_datetime >= dateadd(year, -1, '2025-12-31'::date)
          )
          or (
            lower(document_tag_values) like '%cologuard%' 
            and creation_datetime >= dateadd(year, -3, '2025-12-31'::date)
          )
          or (
            (is_sigmoidoscopy_negative = 1 or is_sigmoidoscopy_positive = 1)
            and creation_datetime >= dateadd(year, -5, '2025-12-31'::date)
          )
          or (
            lower(document_tag_values) like '%ct colonography%'
            and creation_datetime >= dateadd(year, -5, '2025-12-31'::date)
          )
          or (
            (is_colonoscopy_negative = 1 or is_colonoscopy_positive = 1)
            and creation_datetime >= dateadd(year, -10, '2025-12-31'::date)
          )
      )
    qualify rn = 1
)   

, stage_three_a as (
    select 
        suvida_id, 
        icd_10_code_description as evidence_desc,
        date(diagnosis_date) as evidence_date,
        'Colorectal Cancer Screening' as quality_measure, 
        '3' as stage, 
        'Open' as gap_status, 
        'Exclusion Identified' as stage_name, 
        year(diagnosis_date) as measure_year,
        object_construct(
            'id', visit_note_id,
            'elation_object', 'Bill',
            'evidence_date', date(diagnosis_date),
            'evidence_string', icd_10_code_description,
            'evidence_description', concat('Exclusion Identified on ',to_varchar(diagnosis_date, 'MM/DD/YYYY') , ': ', icd_10_code_description)
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_diagnosis
    where source_type = 'emr' 
      and year(diagnosis_date) = year('2025-12-31'::date) 
      and (
            icd_10_code like '%C18%' or
            icd_10_code = 'C19' or
            icd_10_code = 'C20' or 
            icd_10_code = 'C212' or 
            icd_10_code = 'C218' or 
            icd_10_code = 'C785'
            or icd_10_code = 'Z85038' 
            or icd_10_code = 'Z85048'
            or cpt_code in ('44156','44158','44157','44155','44151','44150','44153','44152','44211','44212')
        )
)

, stage_three_b as (
    select 
        suvida_id, 
        concat('Status: ', care_flow_status) as evidence_desc, 
        date(activity_date) as evidence_date,
        'Colorectal Cancer Screening' as quality_measure, 
        '3' as stage, 
        'Open' as gap_status, 
        'Guia Engaged' as stage_name, 
        year(activity_date) as measure_year,
        object_construct(
            'id', activity_id,
            'suvida_object', 'patient_awell_care_flows',
            'evidence_date', date(activity_date),
            'evidence_string', concat(care_flow_name,' ',object_name,' ',track_name,' ',action_name),
            'evidence_description', concat('Guia Engaged on ',to_varchar(activity_date, 'MM/DD/YYYY') )
         ) as quality_engine_info_array,
    from dw_dev.dev_jkizer.patient_awell_care_flows
    where care_flow_name = 'Guia Quality Gap Assistance' 
      and care_flow_status = 'completed'
      and (
            lower(object_name) like '%colorectal%' or
            lower(track_name) like '%colorectal%' or 
            lower(action_name) like '%colorectal%' 
        )
    qualify row_number() over (
        partition by suvida_id, activity_date 
        order by activity_date desc
    ) = 1
)

, stage_four as (
    select
        suvida_id, 
        date(collected_date) as evidence_date, 
        concat(test_category, ' ', test_name, ' ', test_value) as evidence_desc, 
        'Colorectal Cancer Screening' as quality_measure, 
        '4' as stage, 
        'Pending' as gap_status, 
        'Suvida Closed' as stage_name, 
        year(collected_date) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(collected_date),
            'evidence_string', concat('Test Name: ',test_name,'. Test Result: ', test_value),
            'evidence_description', concat('Suvida Closed on ', to_varchar(collected_date, 'MM/DD/YYYY') ,': ',test_name)
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_result
	where (
            (lower(test_category) like '%fit%' or lower(test_name) like '%fit%')
            and collected_date >= dateadd(year, -1, '2025-12-31'::date)
        ) 
        or ((lower(test_category) like '%ifob%' or lower(test_name) like '%ifob%')
            and collected_date >= dateadd(year, -1, '2025-12-31'::date))
        or ((lower(test_category) like '%cologuard%' or lower(test_name) like '%cologuard%')
            and collected_date >= dateadd(year, -3, '2025-12-31'::date))
        or ((lower(test_category) like '%sigmoidoscopy%' or lower(test_name) like '%sigmoidoscopy%')
            and collected_date >= dateadd(year, -5, '2025-12-31'::date))
        or ((lower(test_category) like '%ct colonography%' or lower(test_name) like '%ct colonography%')
            and collected_date >= dateadd(year, -5, '2025-12-31'::date))
        or ((lower(test_category) like '%colonoscopy%' or lower(test_name) like '%colonoscopy%')
            and collected_date >= dateadd(year, -5, '2025-12-31'::date))

    union

    select  
        suvida_id, 
        date(creation_datetime) as evidence_date,
        document_tag_values as evidence_desc,
        'Colorectal Cancer Screening' as quality_measure, 
        '4' as stage, 
        'Pending' as gap_status, 
        'Suvida Closed' as stage_name,
        year(creation_datetime) as measure_year,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', date(creation_datetime),
            'evidence_string', document_tag_values,
            'evidence_description', concat('Suvida Closed on ',to_varchar(document_date, 'MM/DD/YYYY') ,': ', report_title)
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_elation_report
    where num_doc_tags = 1 
      and report_type != 'OldRecord' 
      and lower(report_title) not like '%expired%' 
      and lower(report_title) not like '%past record%' 
      and lower(report_title) not like '%sample not processed%' 
      and (
          ((is_ifobt_negative = 1 or is_ifobt_positive = 1 or is_fit_dna_positive = 1 or is_fit_dna_negative = 1)
            and creation_datetime >= dateadd(year, -1, '2025-12-31'::date))
          or (lower(document_tag_values) like '%cologuard%' 
            and creation_datetime >= dateadd(year, -3, '2025-12-31'::date))
          or ((is_sigmoidoscopy_negative = 1 or is_sigmoidoscopy_positive = 1)
            and creation_datetime >= dateadd(year, -5, '2025-12-31'::date))
          or (lower(document_tag_values) like '%ct colonography%'
            and creation_datetime >= dateadd(year, -5, '2025-12-31'::date))
          or ((is_colonoscopy_negative = 1 or is_colonoscopy_positive = 1)
            and creation_datetime >= dateadd(year, -10, '2025-12-31'::date))
      )
    qualify row_number() over (
        partition by suvida_id 
        order by creation_datetime desc, report_id desc
    ) = 1
)

, stage_five as (
    select 
        suvida_id, 
        workflow_status_detail as evidence_desc,
        date(last_modified_datetime) as evidence_date,
        'Colorectal Cancer Screening' as quality_measure, 
        '5' as stage, 
        'Pending' as gap_status, 
        'Supplemental Data Submitted' as stage_name, 
        year(last_modified_datetime) as measure_year,
        object_construct(
            'id',quality_measure_skey ,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', date(last_modified_datetime), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY') )
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Colorectal Cancer Screening'
        and workflow_status_detail = 'Submitted - Pending Payer Audit'
        and workflow_status_index = 1
        and is_automated_activity = false
)

, stage_six as (
    select 
        suvida_id, 
        measure_source as evidence_desc, 
        date(report_date) as evidence_date,
        quality_measure, 
        '6' as stage, 
        'Closed' as gap_status, 
        'Payer Closed' as stage_name,
        year(measure_year) as measure_year,
        object_construct(
            'id',quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 1 
        and quality_measure = 'Colorectal Cancer Screening'
        and measure_year_report_rank = 1  
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
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
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_d
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_e
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_f
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
    )
;


  