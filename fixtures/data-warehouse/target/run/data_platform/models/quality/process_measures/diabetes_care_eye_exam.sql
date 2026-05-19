
  
    

create or replace transient table dw_dev.dev_jkizer_quality.diabetes_care_eye_exam
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
            'evidence_date', report_date, 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Opened on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 0
        and quality_measure = 'Diabetes Care - Eye Exam'
        and measure_year_report_rank = 1
        and year(measure_year) >= year('2025-12-31'::date) - 2
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)

, stage_two as (
    select 
        year(creation_date_time) as measure_year,
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed' as stage_name, 
        creation_date as evidence_date, 
        test_name as evidence_desc,
        object_construct(
            'id', order_id,
            'elation_object', 'Letter',
            'evidence_date', creation_date, 
            'evidence_string', test_name,
            'evidence_description', concat('Order placed for ', test_name,' on ', to_varchar(creation_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_misc_orders
    where lower(test_name) like '%digital retina exam%'
      and resolution_state = 'outstanding'
      and creation_date > current_date() - interval '60 days'
      and year(creation_date) = year('2025-12-31'::date)
)

, stage_two_a as (
    select
        year(creation_date_time) as measure_year,
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed - Overdue' as stage_name, 
        creation_date as evidence_date, 
        concat(test_name,' ',resolution_state) as evidence_desc,
        object_construct(
            'id', order_id,
            'elation_object', 'Letter',
            'evidence_date', creation_date, 
            'evidence_string', test_name,
            'evidence_description', concat('Order placed for ', test_name,' on ', to_varchar(creation_date, 'MM/DD/YYYY'),' is >60 days overdue')
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_misc_orders
    where resolution_state = 'outstanding'
      and (lower(test_name) like '%digital retina exam%'
        or lower(test_name) like '%digital retinal exam%'
        or test_name like '%DRE%' )
      and creation_date < current_date() - interval '60 days'
      and year(creation_date) = year('2025-12-31'::date)
)

, stage_two_b as (
    select 
        year(creation_datetime) as measure_year, 
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Referral Placed' as stage_name, 
        referral_body_text as evidence_desc, 
        last_modified_datetime as evidence_date,
        object_construct(
            'id', referral_id,
            'elation_object', 'Letter',
            'evidence_date', last_modified_datetime, 
            'evidence_string', referral_body_text,
            'evidence_description', concat('Referral placed on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_referral
    where (
            lower(referral_body_text) like '%digital retina exam%'
            or lower(referral_body_text) like '%diabetic retinopathy%'
            or lower(referral_body_text) like '%retinopathy%'
        )
        and resolution_state = 'outstanding'
        and year(creation_datetime) >= year('2025-12-31'::date) - 2
)

, stage_two_c as (
    select 
        year(last_modified_datetime) as measure_year,
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure,
        '2' as stage, 
        'Open' as gap_status, 
        'Records Requested' as stage_name, 
        workflow_status_detail as evidence_desc,
        last_modified_datetime as evidence_date,
        object_construct(
            'id', quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', last_modified_datetime, 
            'evidence_string', workflow_note,
            'evidence_description', concat('Records Request on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Diabetes Care - Eye Exam'
      and workflow_status_detail = 'Requested Record'
      and workflow_status_index = 1
      and is_automated_activity = false
      and year(last_modified_datetime) >= year('2025-12-31'::date) - 2
)

, stage_three as (
    select
        year(a.document_date) as measure_year,
        a.suvida_id,
        'Diabetes Care - Eye Exam' as quality_measure,
        '3' as stage,
        'Open' as gap_status,
        'DRE Done - Missing CPT' as stage_name,
        a.report_title as evidence_desc,
        a.document_date as evidence_date,
        object_construct(
            'id', report_id,
            'elation_object', 'Report',
            'evidence_date', document_date,
            'evidence_report_title', report_title,
            'evidence_string', document_tag_values,
            'evidence_description', concat('DRE completed on ', to_varchar(document_date, 'MM/DD/YYYY'), ' but is missing CPT codes')
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_elation_report a
    where (report_title like '%DRE%'
      or lower(document_tag_values) like '%retinopathy%'
      or lower(report_title) like '%digital retina exam%'
      or lower(report_title) like '%digital retinal exam%'
      or lower(report_title) like '%retina%')
    and not exists (
        select 1
        from dw_dev.dev_jkizer.fct_procedure b
        where b.suvida_id = a.suvida_id
          and b.cpt_code in ('2022F','2023F')
          and year(b.encounter_date) = year(a.document_date)
          and month(b.encounter_date) = month(a.document_date)
      )
      and year(document_date) >= year('2025-12-31'::date) - 2
)

, stage_three_a as (
    select 
        suvida_id, 
        year(activity_date) as measure_year,
        'Diabetes Care - Eye Exam' as quality_measure,
        '3' as stage, 
        'Open' as gap_status, 
        'Guia Engaged' as stage_name, 
        concat('Status: ', care_flow_status) as evidence_desc, 
        activity_date as evidence_date,
        object_construct(
            'id', activity_id,
            'suvida_object', 'patient_awell_care_flows',
            'evidence_date', activity_date,
            'evidence_string', concat(care_flow_name,' ',object_name,' ',track_name,' ',action_name,' ', care_flow_status),
            'evidence_description', concat('Guia Engaged on ', to_varchar(activity_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.patient_awell_care_flows
    where care_flow_name = 'Guia Quality Gap Assistance'
      and care_flow_status = 'completed'
      and (
            lower(object_name) like '%diabetic eye exam%'
         or lower(track_name) like '%diabetic eye exam%'
         or lower(action_name) like '%diabetic eye exam%'
      )
      and year(activity_date) >= year('2025-12-31'::date) - 2
    qualify row_number() over (
        partition by suvida_id, activity_date
        order by activity_date desc
    ) = 1
)

, stage_three_b as (
    select 
        year(encounter_date) as measure_year,
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure,
        '3' as stage,
        'Open' as gap_status,
        'Negative Result Last Year - Missing CPT (3072F)' as stage_name,
        cpt_code as evidence_desc,
        encounter_date as evidence_date,
        object_construct(
            'id', encounter_skey,
            'elation_object', 'Billing Code',
            'evidence_date', encounter_date,
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Negative result last year (CPT 2023F) on ', to_varchar(encounter_date, 'MM/DD/YYYY'),' but missing CPT 3072F this year')
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_procedure fp
    where cpt_code = '2023F'
      and not exists (
            select 1
            from dw_dev.dev_jkizer.fct_procedure fp2
            where fp2.suvida_id = fp.suvida_id
              and year(fp2.encounter_date) = year(fp.encounter_date) + 1
              and fp2.cpt_code = '3072F'
        )
      and encounter_date is not null
      and year(encounter_date) >= year('2025-12-31'::date) - 3
)

, stage_three_c as (
    select year(diagnosis_date) as measure_year,
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure,
        '3' as stage,
        'Open' as gap_status,
        'Exclusion Identified' as stage_name,
        concat('CPT Code ', cpt_code, ' ICD 10 Code ', icd_10_code, ' ', icd_10_code_description) as evidence_desc,
        diagnosis_date as evidence_date,
        object_construct(
            'id', visit_note_id,
            'elation_object', 'Bill',
            'evidence_date', diagnosis_date,
            'evidence_string', icd_10_code_description,
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Exclusion Identified on ', to_varchar(diagnosis_date, 'MM/DD/YYYY'), ': ', icd_10_code_description)
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_diagnosis d
    left join dw_dev.dev_jkizer.intmdt_medical_claim med
      on d.suvida_id = med.patient_id
      and med.hcpcs_code in ('08T1XZZ', '08T0XZZ')
      and med.hcpcs_modifier_1 = '50'
    where (
            (d.cpt_code in ('65091', '65093', '65101', '65103', '65105', '65110', '65112', '65114')
             and med.hcpcs_code is not null)
         or (icd_10_code in ('Z515', 'Z66', 'R99', 'I469')
             or d.cpt_code in ('Q5001','Q5002','Q5003','Q5004','Q5005','Q5006',
                             'Q5007','Q5008','Q5009','Q5010',
                             'G9473','G9474','G9475','G9476','G9477','G9478','G9479'))
        )
      and year(diagnosis_date) = year('2025-12-31'::date)
)

, stage_four as (
    select year(encounter_date) as measure_year,
        suvida_id, 
        'Diabetes Care - Eye Exam' as quality_measure,
        '4' as stage,
        'Pending' as gap_status,
        'Suvida Closed' as stage_name,
        cpt_code as evidence_desc,
        encounter_date as evidence_date,
        object_construct(
            'id', encounter_skey,
            'elation_object', 'Billing Code',
            'evidence_date', encounter_date,
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Suvida Closed on ', to_varchar(encounter_date, 'MM/DD/YYYY'), ': CPT Code ', cpt_code)
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('2022F','2023F','3072F')
      and year(encounter_date) >= year('2025-12-31'::date) - 2
)

, stage_five as (
    select 
        year(last_modified_datetime) as measure_year,
        suvida_id,
        quality_measure,
        '5' as stage,
        'Pending' as gap_status,
        'Supplemental Data Submitted' as stage_name,
        workflow_status_detail as evidence_desc,
        last_modified_datetime as evidence_date,
        object_construct(
            'id', quality_measure_skey,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', last_modified_datetime, 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Diabetes Care - Eye Exam'
      and workflow_status_detail = 'Submitted - Pending Payer Audit'
      and workflow_status_index = 1
      and is_automated_activity = false
      and year(last_modified_datetime) >= year('2025-12-31'::date) - 2
)

, stage_six as (
   select 
        year(measure_year) as measure_year, 
        suvida_id, 
        quality_measure, 
        '6' as stage, 
        'Closed' as gap_status, 
        'Payer Closed' as stage_name, 
        measure_source as evidence_desc, 
        report_date as evidence_date,
        object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', report_date, 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 1
      and quality_measure = 'Diabetes Care - Eye Exam'
      and measure_year_report_rank = 1
      and year(measure_year) >= year('2025-12-31'::date) - 2
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)

, combined_data as (
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_one
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_a
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_b
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two_c
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_a
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_b
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_c
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_four
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_five
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_six
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

select
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


  