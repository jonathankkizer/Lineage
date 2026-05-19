
  
    

create or replace transient table dw_dev.dev_jkizer_quality.statin_therapy_for_cardio_disease
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
		and quality_measure = 'Statin Therapy for Cardiovascular Disease'
		and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date desc
    ) = 1
)
, stage_two as (
    select
        year(coalesce(signed_datetime, last_fill_date)) as measure_year,
        suvida_id, 
        coalesce(signed_datetime, last_fill_date) as evidence_date,
        'Statin Therapy for Cardiovascular Disease' as quality_measure, 
        '2' as stage,
        'Open' as gap_status, 
        'Mod-High Intensity Statin Required' as stage_name, 
        displayed_medication_name as evidence_desc,
        object_construct(
            'id', med_order_fill_id,
            'elation_object', 'Medication Order Template',
            'evidence_date', coalesce(signed_datetime, last_fill_date), 
            'evidence_string', displayed_medication_name,
            'evidence_description', concat('Dosage of ', displayed_medication_name, regexp_substr(strength, '^[0-9]+(\.[0-9]+)?'), ' on ', to_varchar(coalesce(signed_datetime, last_fill_date), 'MM/DD/YYYY'), ' is not high enough')
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.patient_med_order_fill
    where (lower(displayed_medication_name) like '%atorvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 10) or 
        (lower(displayed_medication_name) like '%amlodipine-atorvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 10) or
        (lower(displayed_medication_name) like '%rosuvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 5) or
        (lower(displayed_medication_name) like '%simvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 20) or 
        (lower(displayed_medication_name) like '%ezetimibe-simvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 20) or
        (lower(displayed_medication_name) like '%pravastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 40) or 
        (lower(displayed_medication_name) like '%lovastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 40) or 
        (lower(displayed_medication_name) like '%fluvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 40) or 
        (lower(displayed_medication_name) like '%pitavastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) > 1)
)

, stage_three as (
    select 
        year(signed_datetime) as measure_year,
        suvida_id, 
        'Statin Therapy for Cardiovascular Disease' as quality_measure, 
        '3' as stage, 
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
    from dw_dev.dev_jkizer.patient_med_order_fill 
    where 
    (lower(displayed_medication_name) like '%atorvastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 10) or 
    (lower(displayed_medication_name) like '%amlodipine-atorvastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 10) or
    (lower(displayed_medication_name) like '%rosuvastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 5) or
    (lower(displayed_medication_name) like '%simvastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 20) or 
    (lower(displayed_medication_name) like '%ezetimibe-simvastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 20) or
    (lower(displayed_medication_name) like '%pravastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 40) or 
    (lower(displayed_medication_name) like '%lovastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 40) or 
    (lower(displayed_medication_name) like '%fluvastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 40) or 
    (lower(displayed_medication_name) like '%pitavastatin%' 
        and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) < 1)
)
, stage_four_a as (
    select 
        year(last_fill_date) as measure_year,
        suvida_id, 
        'Statin Therapy for Cardiovascular Disease' as quality_measure, 
        '4' as stage, 
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
    from dw_dev.dev_jkizer.patient_med_order_fill 
    where (lower(displayed_medication_name) like '%atorvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 10) or 
        (lower(displayed_medication_name) like '%amlodipine-atorvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 5) or
        (lower(displayed_medication_name) like '%rosuvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 5) or
        (lower(displayed_medication_name) like '%simvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 20) or 
        (lower(displayed_medication_name) like '%ezetimibe-simvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 20) or
        (lower(displayed_medication_name) like '%pravastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 40) or 
        (lower(displayed_medication_name) like '%lovastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 40) or 
        (lower(displayed_medication_name) like '%fluvastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 40) or 
        (lower(displayed_medication_name) like '%pitavastatin%' and try_to_number(regexp_substr(strength, '^[0-9]+(\.[0-9]+)?')) >= 1)
)
, stage_four_b as (
    select year(diagnosis_date) as measure_year,
        d.suvida_id, 
        'Statin Therapy for Cardiovascular Disease' as quality_measure,
        '4' as stage,
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
    from dw_dev.dev_jkizer.fct_diagnosis  d 
        join dw_dev.dev_jkizer.patient_med_order_fill  med on d.suvida_id = med.suvida_id 
            and year(d.diagnosis_date) = year(med.last_fill_date)
    where (
            --deceased/hospice
            (
                icd_10_code in ('Z515', 'Z66', 'R99', 'I469') or 
                cpt_code in ('Q5001', 'Q5002', 'Q5003', 'Q5004', 'Q5005','Q5006', 'Q5007', 'Q5008', 'Q5009', 'Q5010','G9473', 'G9474', 'G9475', 'G9476', 'G9477', 'G9478','G9479')
            )
            or lower(icd_10_code_description) like '%esrd%'
            or icd_10_code = 'O99019' --pregnancy
        )
        and year(d.diagnosis_date) = year('2025-12-31'::date)
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
        and quality_measure = 'Statin Therapy for Cardiovascular Disease'
        and measure_year_report_rank = 1
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
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_three
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_four_a
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_four_b
    union all
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, quality_engine_info_array from stage_five
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
    gap_status as med_adherence_gap_status,
    evidence_date,
    evidence_desc,
    latest_rank_overall,
    quality_engine_info_array
from ranked
    )
;


  