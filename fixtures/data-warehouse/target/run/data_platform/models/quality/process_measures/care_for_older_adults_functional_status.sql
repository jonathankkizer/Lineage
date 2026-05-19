
  
    

create or replace transient table dw_dev.dev_jkizer_quality.care_for_older_adults_functional_status
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
        and quality_measure = 'Care for Older Adults - Functional Status'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)

, stage_two as (
    select 
        year(appointment_date) as measure_year, 
        suvida_id, 
        'Care for Older Adults - Functional Status' as quality_measure,
        '2' as stage,
        'Open' as gap_status,
        'AWV Scheduled' as stage_name,
        date(appointment_date) as evidence_date,
        concat(appointment_description, '. Status: ', appointment_status) as evidence_desc,
        object_construct(
            'id', appointment_id,
            'elation_object', 'Appointments',
            'evidence_date', date(appointment_date),
            'evidence_string', concat('Appointment Description: ', appointment_description, '. Status: ', appointment_status),
            'evidence_description', concat('AWV Scheduled on ', to_varchar(appointment_date, 'MM/DD/YYYY'))
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_appointment
    where (lower(appointment_description) like '%patient annual wellness%' 
        or lower(appointment_description) like '%awv%' 
        or lower(appointment_type_category) like '%awv%'
        or lower(appointment_type) like '%awv%')
        and appointment_status = 'scheduled'
        and appointment_date >= current_date()
        and year(appointment_date) = year('2025-12-31'::date)
)

, stage_three_a as (
    select 
        year(encounter_date) as measure_year, 
        suvida_id,
        'Care for Older Adults - Functional Status' as quality_measure,
        '3' as stage,
        'Open' as gap_status,
        'FSA Complete - Missing ADL' as stage_name,
        date(encounter_date) as evidence_date,
        cpt_code as evidence_desc,
        object_construct(
            'id', encounter_skey,
            'elation_object', 'Billing Code',
            'evidence_date', date(encounter_date),
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('FSA Complete with CPT Code: ', cpt_code,' on ',to_varchar(encounter_date, 'MM/DD/YYYY'), ' but missing ADL')
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('1170F','99483')
	    and year(encounter_date) = year('2025-12-31'::date)
)

, stage_three_b as (
    select ph.suvida_id,
       'Care for Older Adults - Functional Status' as quality_measure,
       '3' as stage,
       'Open' as gap_status,
       'ADL Complete - Missing FSA' as stage_name,
       concat(ph.history_type, ' ', ph.history_value) as evidence_desc, 
       date(ph.creation_datetime) as evidence_date, 
       year(ph.creation_datetime) as measure_year,
       object_construct(
            'elation_object', 'History',
            'evidence_date', date(ph.creation_datetime),
            'evidence_string', ph.history_type,
            'evidence_numeric', ph.history_value,
            'evidence_description', concat('ADL Complete with ', ph.history_type,' on ',to_varchar(ph.creation_datetime, 'MM/DD/YYYY'), ' with value of ', ph.history_value, ' but missing FSA')
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_patient_history ph 
    join dw_dev.dev_jkizer.fct_procedure p 
        on ph.suvida_id = p.suvida_id 
        and year(ph.creation_datetime) = year(p.encounter_datetime)
    where ph.history_type = 'KATZ-ADL'
        and not exists (
            select 1
            from dw_dev.dev_jkizer.fct_procedure p2 
            where p2.suvida_id = ph.suvida_id
                and year(p2.encounter_datetime) = year(ph.creation_datetime)
                and p2.cpt_code in ('1170F','99483')
        )
)

, stage_four as (
    select ph.suvida_id,
        'Care for Older Adults - Functional Status' as quality_measure,
        '4' as stage,
        'Pending' as gap_status,
        'Suvida Closed' as stage_name,
        concat(ph.history_type,' Value: ',ph.history_value, ' CPT_CODE: ', cpt_code) as evidence_desc, 
        date(greatest(ph.creation_datetime, p.encounter_date)) as evidence_date, 
        year(ph.creation_datetime) as measure_year,
        object_construct(
            'elation_object', 'History',
            'evidence_date', date(greatest(ph.creation_datetime, p.encounter_date)),
            'evidence_string', ph.history_type,
            'evidence_numeric', ph.history_value,
            'evidence_cpt_code', cpt_code,
            'evidence_cpt_date', p.encounter_date,
            'evidence_description', concat('Suvida Closed on ',to_varchar(greatest(ph.creation_datetime, p.encounter_date), 'MM/DD/YYYY'))
         ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_patient_history ph 
    join dw_dev.dev_jkizer.fct_procedure p 
        on ph.suvida_id = p.suvida_id 
        and year(ph.creation_datetime) = year(p.encounter_datetime)
        and p.cpt_code in ('1170F', '99483')
    where ph.history_type = 'KATZ-ADL'
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
    where quality_measure = 'Care for Older Adults - Functional Status'
        and workflow_status_detail = 'Submitted - Pending Payer Audit'
        and workflow_status_index = 1
        and is_automated_activity = false
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
        date(report_date) as evidence_date,
        object_construct(
            'id', quality_measure_report_skey,
            'suvida_object', 'fct_quality_measure',
            'evidence_date', date(report_date), 
            'evidence_string', measure_status,
            'evidence_description', concat('Quality Measure Closed on ', to_varchar(report_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_quality_measure
    where measure_numerator = 1 
        and quality_measure = 'Care for Older Adults - Functional Status'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)

, combined_data as (
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_one
    union all
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two
    union all
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_a
    union all
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_b
    union all
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_four
    union all
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_five
    union all
    select  suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_six
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


  