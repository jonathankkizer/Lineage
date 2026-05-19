
  
    

create or replace transient table dw_dev.dev_jkizer_quality.statin_use_in_persons_with_diabetes
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
		and quality_measure = 'Statin Use in Persons with Diabetes'
		and measure_year_report_rank = 1
		and year(measure_year) >= year('2025-12-31'::date) - 2
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)
-- Base CTE: Scan patient_med_order_fill once for statin medications
, statin_medications as (
    select
        suvida_id,
        signed_datetime,
        last_fill_date,
        displayed_medication_name,
        med_order_fill_id
    from dw_dev.dev_jkizer.patient_med_order_fill
    where (lower(displayed_medication_name) like '%atorvastatin%' or
        lower(displayed_medication_name) like '%lovastatin%' or
        lower(displayed_medication_name) like '%pravastatin%' or
        lower(displayed_medication_name) like '%simvastatin%' or
        lower(displayed_medication_name) like '%ezetimibe-simvastatin%' or
        lower(displayed_medication_name) like '%rosuvastatin%' or
        lower(displayed_medication_name) like '%amlodipine-atorvastatin%' or
        lower(displayed_medication_name) like '%fluvastatin%' or
        lower(displayed_medication_name) like '%livalo%')
        and (year(signed_datetime) >= year('2025-12-31'::date) - 2
          or year(last_fill_date) >= year('2025-12-31'::date) - 2)
)
, stage_two as (
    select
        year(signed_datetime) as measure_year,
        suvida_id,
        'Statin Use in Persons with Diabetes' as quality_measure,
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
            'evidence_description', concat('Prescription for ', displayed_medication_name, ' sent on ', to_varchar(signed_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from statin_medications
    where signed_datetime is not null
)
, stage_three_a as (
    select
        year(last_fill_date) as measure_year,
        suvida_id,
        'Statin Use in Persons with Diabetes' as quality_measure,
        '3' as stage,
        'Pending' as gap_status,
        'Prescription Filled' as stage_name,
        last_fill_date as evidence_date,
        displayed_medication_name as evidence_desc,
        object_construct(
            'id', med_order_fill_id,
            'elation_object', 'Medication Order Template',
            'evidence_date', date(last_fill_date),
            'evidence_string', displayed_medication_name,
            'evidence_description', concat(displayed_medication_name, ' last filled on: ', to_varchar(last_fill_date, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from statin_medications
    where last_fill_date is not null
)
, stage_three_b as (
    select year(diagnosis_date) as measure_year,
        d.suvida_id, 
        'Statin Use in Persons with Diabetes' as quality_measure,
        '3' as stage,
        'Pending' as gap_status,
        'Exclusion Identified' as stage_name,
        concat('CPT Code ', cpt_code, 'ICD 10 Code ', icd_10_code, ' ', icd_10_code_description) as evidence_desc,
        diagnosis_date as evidence_date,
        object_construct(
            'id', visit_note_id,
            'elation_object', 'Bill',
            'evidence_date', date(diagnosis_date),
            'evidence_string', icd_10_code_description,
            'evidence_cpt_code', cpt_code,
            'evidence_description', concat('Exclusion Identified on ', to_varchar(diagnosis_date, 'MM/DD/YYYY'), ': ', icd_10_code_description)
        ) as quality_engine_info_array 
    from dw_dev.dev_jkizer.fct_diagnosis d 
        join dw_dev.dev_jkizer.patient_med_order_fill med on d.suvida_id = med.suvida_id 
            and year(d.diagnosis_date) = year(med.last_fill_date)
    where (
            --deceased/hospice
            icd_10_code in ('Z515', 'Z66', 'R99', 'I469') or 
            cpt_code in ('Q5001', 'Q5002', 'Q5003', 'Q5004', 'Q5005','Q5006', 'Q5007', 'Q5008', 'Q5009', 'Q5010','G9473', 'G9474', 'G9475', 'G9476', 'G9477', 'G9478','G9479') or 
            lower(icd_10_code_description) like '%esrd%' or
            icd_10_code = 'O99019' --pregnancy
        )
        and year(d.diagnosis_date) = year('2025-12-31'::date)
)
, stage_four as (
   select 
        year(measure_year) as measure_year, 
        suvida_id, 
        quality_measure, 
        '4' as stage, 
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
        and quality_measure = 'Statin Use in Persons with Diabetes'
        and measure_year_report_rank = 1
        and year(measure_year) >= year('2025-12-31'::date) - 2
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
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
    select distinct *
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
                date(evidence_date) desc
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
    gap_status as med_adherence_gap_status,
    evidence_date,
    evidence_desc,
    latest_rank_overall,
    quality_engine_info_array
from ranked
    )
;


  