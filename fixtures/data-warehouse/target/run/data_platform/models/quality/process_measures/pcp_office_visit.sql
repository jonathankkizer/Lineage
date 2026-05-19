
  
    

create or replace transient table dw_dev.dev_jkizer_quality.pcp_office_visit
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
        and quality_measure = 'PCP Office Visit'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)
, stage_two as (
    select 
        year(appointment_date) as measure_year, 
        suvida_id, 
        'PCP Office Visit' as quality_measure,
        '2' as stage,
        'Open' as gap_status,
        'Visit Scheduled' as stage_name,
        appointment_date as evidence_date,
        concat(appointment_description, '. Status: ', appointment_status) as evidence_desc,
        object_construct(
            'id', appointment_id,
            'elation_object', 'Appointments',
            'evidence_date', date(appointment_date),
            'evidence_string', concat('Appointment Description: ', appointment_description, '. Status: ', appointment_status),
            'evidence_description', concat('Visit Scheduled on ', to_varchar(appointment_date, 'MM/DD/YYYY'))
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_appointment
    where is_pcp_appt = TRUE and 
        appointment_status = 'scheduled' and
        appointment_date >= current_date()
        and year(appointment_date) = year('2025-12-31'::date)
)
, stage_three as (
    select 
        year(encounter_date) as measure_year, 
        suvida_id, 
        'PCP Office Visit' as quality_measure,
        '3' as stage,
        'Pending' as gap_status,
        'Suvida Closed' as stage_name,
        encounter_date as evidence_date,
        concat(provider_name, ' ', note_text) as evidence_desc,
        object_construct(
            'id', encounter_skey,
            'suvida_object', 'fct_encounter',
            'evidence_date', date(encounter_date), 
            'evidence_string', note_text,
            'evidence_description', concat('PCP Office visit on ', to_varchar(encounter_date, 'MM/DD/YYYY'),' with ', provider_name)
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_encounter
    where visit_note_name = 'Provider Note' or  
        encounter_type = 'Clinical Encounter' or
        encounter_type = 'clinical_encounter' 
)
, stage_five as (
   select 
        year(measure_year) as measure_year, 
        suvida_id, 
        quality_measure, 
        '5' as stage, 
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
        and quality_measure = 'PCP Office Visit'
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


  