
  
    

create or replace transient table dw_dev.dev_jkizer_quality.care_for_older_adults_medication_review
    copy grants
    
    
    as (with stage_one as (
    select
        year(measure_year) as measure_year,
        suvida_id,
        quality_measure,
        '1' as stage,
        'Open' as gap_status,
        'Not Started' as stage_name,
        date(report_date) as evidence_date,
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
      and quality_measure = 'Care for Older Adults - Medication Review'
      and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc, quality_measure_report_skey asc
    ) = 1    
)

, stage_two as (
    select 
        year(appointment_date) as measure_year, 
        suvida_id, 
        'Care for Older Adults - Medication Review' as quality_measure,
        '2' as stage,
        'Open' as gap_status,
        'AWV Scheduled' as stage_name,
        date(appointment_date) as evidence_date,
        concat(appointment_description, ' ', appointment_status) as evidence_desc,
        object_construct(
            'id', appointment_id,
            'elation_object', 'Appointments',
            'evidence_date', date(appointment_date),
            'evidence_string', concat('Appointment Description: ', appointment_description, '. Status: ', appointment_status),
            'evidence_description', concat('AWV Scheduled on ', to_varchar(appointment_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_appointment
    where (
        lower(appointment_description) like '%patient annual wellness%' 
        or lower(appointment_description) like '%awv%' 
        or lower(appointment_type_category) like '%awv%'
        or lower(appointment_type) like '%awv%'
        )
        and appointment_status = 'scheduled'
        and appointment_date >= current_date()
        and year(appointment_date) = year('2025-12-31'::date)
)

, stage_three_a as (
    select 
        year(encounter_date) as measure_year, 
        suvida_id,
        'Care for Older Adults - Medication Review' as quality_measure,
        '3' as stage,
        'Open' as gap_status,
        'Medication List Documented' as stage_name,
        date(encounter_date) as evidence_date,
        cpt_code as evidence_desc,
        object_construct(
            'id', encounter_skey,
            'elation_object', 'Billing Code',
            'evidence_date', date(encounter_date),
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Medication List Documented (CPT 1159F) on ', to_varchar(encounter_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array     
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('1159F')
      and year(encounter_date) = year('2025-12-31'::date)
    group by all
    having count(distinct cpt_code) = 1
        and max(cpt_code) = '1159F'
)

, stage_three_b as (
    select 
        year(encounter_date) as measure_year, 
        suvida_id,
        'Care for Older Adults - Medication Review' as quality_measure,
        '3' as stage,
        'Open' as gap_status,
        'Medication Review Documented' as stage_name,
        date(encounter_date) as evidence_date,
        listagg(cpt_code, ' | ') as evidence_desc,
        object_construct(
            'id', encounter_skey,
            'elation_object', 'Billing Code',
            'evidence_date', date(encounter_date),
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Medication Reviewed (CPT 1160F) on ',to_varchar(encounter_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array  
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('1160F')
      and year(encounter_date) = year('2025-12-31'::date)
    group by all
    having 
        count(distinct cpt_code) = 1
        and max(cpt_code) = '1160F'
)

, stage_four as ( 
    select 
        year(encounter_date) as measure_year, 
        suvida_id,
        'Care for Older Adults - Medication Review' as quality_measure,
        '4' as stage,
        'Pending' as gap_status,
        'Suvida Closed' as stage_name,
        date(encounter_date) as evidence_date,
        listagg(cpt_code, ' | ') as evidence_desc,
        object_construct(
            'elation_object', 'Billing Code',
            'evidence_date', date(encounter_date),
            'evidence_cpt_code', listagg(cpt_code, ' | '),
            'evidence_description', concat('Suvida closed on ', to_varchar(encounter_date, 'MM/DD/YYYY'), ': CPT Codes 1160F and 1159F')
        ) as quality_engine_info_array  
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('1160F', '1159F')
    group by suvida_id, encounter_date
    having count(distinct cpt_code) = 2
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
        date(last_modified_datetime) as evidence_date,
        object_construct(
            'id',quality_measure_skey ,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', date(last_modified_datetime), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Care for Older Adults - Medication Review'
        and workflow_status_detail = 'Submitted - Pending Payer Audit'
        and workflow_status_index = 1
        and is_automated_activity = false
) 

, stage_six as (
   select year(measure_year) as measure_year, 
        suvida_id, 
        quality_measure, 
        '6' as stage, 
        'Closed' as gap_status, 
        'Payer Closed' as stage_name, 
        measure_source as evidence_desc, 
        date(report_date) as evidence_date,
        object_construct(
            'id',quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 1 
        and quality_measure = 'Care for Older Adults - Medication Review'
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
    from stage_three_a
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_three_b
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_four
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_five
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array 
    from stage_six
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


  