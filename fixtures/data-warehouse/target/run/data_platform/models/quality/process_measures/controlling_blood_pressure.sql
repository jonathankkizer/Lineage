
  
    

create or replace transient table dw_dev.dev_jkizer_quality.controlling_blood_pressure
    copy grants
    
    
    as (with stage_one as (
    select 
        suvida_id, 
        date(report_date) as evidence_date, 
        quality_measure, 
        '1' as stage, 
        'Open' as gap_status, 
        'Not Started' as stage_name, 
        year(measure_year) as measure_year, 
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
        and quality_measure = 'Controlling Blood Pressure'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)

, stage_two as (
    select 
        suvida_id, 
        'Controlling Blood Pressure' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Uncontrolled' as stage_name, 
        concat('Lowest Blood Pressure Reading: ', lowest_blood_pressure_text) as evidence_desc, 
        date(document_datetime) as evidence_date, 
        year(document_datetime) as measure_year,
        object_construct(
            'id', vital_id,
            'elation_object', 'Vital',
            'evidence_date', date(document_datetime),
            'evidence_string', lowest_blood_pressure_text,
            'evidence_description', concat('Uncontrolled due to Lowest Blood Pressure Reading: ', lowest_blood_pressure_text, ' on ', to_varchar(document_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_vital
    where is_lowest_value_controlled_blood_pressure = False
)

, controlled_year as (
    select 
        suvida_id,
        vital_id,
        date(document_datetime) as vital_date,
        lowest_blood_pressure_text,
        year(document_datetime) as yr,
    from dw_dev.dev_jkizer.fct_vital
    where is_lowest_value_controlled_blood_pressure = TRUE
    qualify row_number() over (
        partition by suvida_id, year(document_datetime)
        order by document_datetime desc, vital_id desc
    ) = 1
)

, stage_four as (
    select
        p.suvida_id,
        'Controlling Blood Pressure' as quality_measure,
        '4' as stage,
        'Pending' as gap_status,
        'Controlled' as stage_name,
        date(p.encounter_date) as evidence_date,
        year(p.encounter_date) as measure_year,
        listagg(distinct p.cpt_code, ' | ') within group (order by p.cpt_code) as evidence_desc,
        object_construct(
            'id', max(cy.vital_id),
            'elation_object', 'Vital',
            'evidence_cpt_date', date(p.encounter_date),
            'evidence_cpt_code', listagg(distinct p.cpt_code, ' | ') within group (order by p.cpt_code),
            'evidence_date', max(cy.vital_date),
            'evidence_string', max(cy.lowest_blood_pressure_text),
            'evidence_description', concat('Controlled due to Lowest Blood Pressure Reading ', max(cy.lowest_blood_pressure_text), ' on ', to_varchar(max(cy.vital_date), 'MM/DD/YYYY'), ' and CPT Codes: ', listagg(distinct p.cpt_code, ' | ') within group (order by p.cpt_code), ' on ',date(p.encounter_date))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_procedure p
    join controlled_year cy
        on p.suvida_id = cy.suvida_id
        and year(p.encounter_date) = cy.yr
    where p.cpt_code in ('3074F','3075F','3079F','3078F')
    group by p.suvida_id,
        date(p.encounter_date),
        year(p.encounter_date)
    having
        count(distinct case when p.cpt_code in ('3074F','3075F') then p.cpt_code end) >= 1 
        and count(distinct case when p.cpt_code in ('3079F','3078F') then p.cpt_code end) >= 1
)

, stage_three as (
    select 
        v.suvida_id, 
        'Controlling Blood Pressure' as quality_measure, 
        '3' as stage, 
        'Pending' as gap_status, 
        'Controlled - Missing CPT' as stage_name, 
        lowest_blood_pressure_text as evidence_desc,
        date(document_datetime) as evidence_date, 
        year(document_datetime) as measure_year,
        object_construct(
            'id', vital_id,
            'elation_object', 'Vital',
            'evidence_date', date(document_datetime),
            'evidence_string', lowest_blood_pressure_text,
            'evidence_description', concat('Controlled due to Lowest Blood Pressure Reading: ',lowest_blood_pressure_text, ' on ', to_varchar(document_datetime, 'MM/DD/YYYY'), ' but missing CPT Codes')
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_vital v 
    left join stage_four sf 
        on sf.suvida_id = v.suvida_id
        and date(document_datetime) = sf.evidence_date
    where is_lowest_value_controlled_blood_pressure = TRUE
      and sf.suvida_id is null 
) 

, combined_data as (
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_one
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three
    union all
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_four
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
                evidence_date desc
        ) as latest_rank_overall
    from tagged
)

select distinct
    suvida_id,
    measure_year,
    quality_measure,
    evidence_date,
    evidence_desc,
    stage,
    stage_name,
    gap_status,
    latest_rank_overall,
    quality_engine_info_array
from ranked
    )
;


  