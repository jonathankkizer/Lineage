
  
    

create or replace transient table dw_dev.dev_jkizer.patient_huddle_new
    copy grants
    
    
    as (/*
Unpivoted version of patient_huddle with grain: one row per suvida_id, measure_name
*/

with most_recent_bmi as (
    select
        suvida_id,
        bmi
    from dw_prod.dw.patient_vital
    where bmi is not null
    qualify row_number() over (partition by suvida_id order by creation_datetime desc) = 1
), most_recent_bp as (
    select
        suvida_id,
        Blood_pressure_text,
        date(creation_datetime) as creation_date
    from dw_prod.dw.patient_vital
    where Blood_pressure_text is not null
    qualify row_number() over (partition by suvida_id order by creation_datetime desc) = 1
), most_recent_a1c_value as (
    select
        suvida_id,
        numeric_test_value as a1c_value,
        collected_date
    from dw_prod.dw.fct_lab_result
    where lower(test_name) like '%a1c%'
        and value_type = 'NM'
    qualify row_number() over (partition by suvida_id order by collected_date_time desc) = 1
), most_recent_sdoh as (
    select
        suvida_id,
        case when SDOH_MOST_RECENT_COMPLETION_DATE >= dateadd(month, -12, current_date()) then 'Done' else 'Missing' end as SDOH_completed_past_12_months,
        case when SDOH_MOST_RECENT_COMPLETION_DATE >= dateadd(month, -12, current_date()) then TO_CHAR(SDOH_MOST_RECENT_COMPLETION_DATE, 'YYYY-MM-DD') ELSE 'Not done in past 12 months'
        end as SDOH_Recent_Completion_Date
    from dw_prod.dw.patient_summary
), most_recent_roi as (
  select  
    suvida_id,
    case when roi_most_recent_completion_date >= dateadd(month, -12, current_date()) then 'Valid'
      when roi_most_recent_completion_date is null then 'Never Completed' else 'Renewal Needed'
    end as roi_completed_past_12_months,
    case when roi_most_recent_completion_date >= dateadd(month, -12, current_date()) then TO_CHAR(roi_most_recent_completion_date, 'YYYY-MM-DD')
      when roi_most_recent_completion_date is null then '' else 'Expired'
  end as roi_recent_completion_date
  from dw_dev.dev_jkizer.patient_summary  
), patient_history_measures as (
    select
        suvida_id,
        mini_cog_value as dementia_minicog,
        phq_2_value as depression_phq2,
        phq_9_value as depression_phq9,
        alcohol_use_audit_c_value as alcohol_auditc
    from dw_dev.dev_jkizer.patient_history
), current_payer_quality as (
    select
        pma.med_adherence_measure_skey as measure_skey,
        pma.suvida_id,
        pma.quality_measure,
        coalesce(to_char(pma.current_quality_engine_quality_engine_info_array), concat('Next Refill:',pma.NEXT_REFILL_DUE, '|','PDC:', pma.PERC_DAYS_COVERED, '|', 'GDR:',pma.GAP_DAYS_REMAINING, '|', pma.RX_NAME)) as measure_detail,
        pma.measure_status,
        pma.measure_numerator,
        pma.PERC_DAYS_COVERED as "pdc",
        pma.GAP_DAYS_REMAINING as "gap_days",
        pma.NEXT_REFILL_DUE  as "next_refill_date",
        pma.RX_NAME  as "medication_name",
        coalesce(pma.current_quality_engine_status, initcap(pma.measure_status)) as current_quality_engine_status
    from dw_dev.dev_jkizer.patient_med_adherence pma
    where pma.is_measure_year_current_report = 'TRUE'
    and pma.is_single_fill = 0
    and year(measure_year) = year(current_date())

    union
    select
        pqm.quality_measure_skey as measure_skey,
        pqm.suvida_id,
        pqm.quality_measure,
        coalesce(to_char(pqm.current_quality_engine_quality_engine_info_array), pqm.measure_detail) as measure_detail,
        pqm.measure_status,
        pqm.measure_numerator,
        null as "pdc",
        null as "gap_days",
        null as "next_refill_date",
        null as "medication_name",
        coalesce(pqm.current_quality_engine_status, iff(measure_detail is not null, 'Closed', 'Open')) as current_quality_engine_status
    from dw_dev.dev_jkizer.patient_quality_measure pqm
    where pqm.is_measure_year_current_report = 1
    and year(measure_year) = year(current_date())
    and pqm.quality_measure not like 'Med%'
), payer_quality_stars_combined_logic as (
    select
        measure_skey,
        coalesce(pq.suvida_id, ssl.suvida_id) as suvida_id,
        coalesce(pq.quality_measure, ssl.quality_measure) as quality_measure,
        pq.measure_status as payer_measure_status,
        pq.measure_detail as payer_measure_detail,
        pq.current_quality_engine_status,
        ssl.suvida_measure_status,
        ssl.evidence_desc as suvida_measure_detail,
        ssl.evidence_date as suvida_evidence_date,
        ssl.evidence_array,
        case
          when greatest_ignore_nulls(ssl.suvida_numerator, pq.measure_numerator) = 1 then 'Closed'
          when greatest_ignore_nulls(ssl.suvida_numerator, pq.measure_numerator) != 1 and ssl.pending_numerator = 1 then 'Coming Up'
          when greatest_ignore_nulls(ssl.suvida_numerator, pq.measure_numerator) != 1 and (ssl.pending_numerator != 1 or ssl.pending_numerator is null) then 'Open'
      end as combined_measure_status,
        concat('Payer: ', pq.measure_status, ' ', coalesce(pq.measure_detail, 'No Detail Available')) as payer_logic_desc,
        concat('Suvida: ', ssl.suvida_measure_status, ' ', ssl.evidence_desc, ' ', evidence_date) as suvida_care_logic_desc  -- Removed trailing comma
    from current_payer_quality pq
    left join dw_dev.dev_jkizer_quality.stars_suvida_logic ssl
        on pq.suvida_id = ssl.suvida_id
        and pq.quality_measure = ssl.quality_measure
    
    union all 

    select 
        null as measure_skey, 
        ssl.suvida_id, 
        ssl.quality_measure, 
        null as payer_measure_status, 
        null as payer_measure_detail, 
        initcap(suvida_measure_status) as current_quality_engine_status,
        ssl.suvida_measure_status,
        ssl.evidence_desc as suvida_measure_detail,
        ssl.evidence_date as suvida_evidence_date,
        ssl.evidence_array,
        suvida_measure_status as combined_measure_status, 
        null as payer_logic_desc, 
        concat('Suvida: ', ssl.suvida_measure_status, ' ', ssl.evidence_desc, ' ', evidence_date) as suvida_care_logic_desc  -- Removed trailing comma
    from dw_dev.dev_jkizer_quality.stars_suvida_logic ssl 
    left join current_payer_quality pq 
        on ssl.suvida_id = pq.suvida_id 
    where ssl.quality_measure in (
        'Suvida - Flu Vaccine',
        'Suvida - Pneumococcal Vaccine',
        'Suvida - covid',
        'Care for Older Adults - Medication Review', 
        'Care for Older Adults - Functional Status',
        'Diabetes Care - Eye Exam',
        'Suvida - Diabetic Foot Exam',
        'Diabetes Care - Kidney Disease Evaluation',
        'suvida-echo',
        'suvida-spiro',
        'Suvida - eGFR',
        'Suvida - Quantaflo'
        ) 

), summarized_care_logic as (
    select
        *,
        concat(
            combined_measure_status, ' | ',
            coalesce(payer_logic_desc, ''), ' | ',
            coalesce(suvida_care_logic_desc, '')
        ) as combined_measure_status_desc,
        case when combined_measure_status like 'Closed' then concat('Done', ' | ', suvida_evidence_date)
        when combined_measure_status like 'Open' then 'Missing'
        else combined_measure_status end as bucket_1_desc,
        combined_measure_status as bucket_2_desc,
        concat(combined_measure_status, ' | ', suvida_measure_detail) as bucket_3_desc,
        payer_logic_desc as bucket_4_desc,
        TRIM(suvida_measure_detail) as bucket_5_desc
    from payer_quality_stars_combined_logic
), patient_base as (
    select
        dp.suvida_id,
        dp.age_year,
        hcc.diabetes_cc_flag,
        hcc.diabetes_non_cc_flag,
        bmi.bmi,
        bp.Blood_pressure_text,
        bp.creation_date as bp_creation_date,
        a1c.a1c_value,
        a1c.collected_date as a1c_collected_date,
        sdoh.SDOH_completed_past_12_months,
        sdoh.SDOH_Recent_Completion_Date,
        phm.dementia_minicog,
        phm.depression_phq2,
        phm.depression_phq9,
        phm.alcohol_auditc
    from dw_dev.dev_jkizer.dim_patient dp
    left join dw_dev.dev_jkizer.patient_hcc_diagnosis hcc
        on dp.suvida_id = hcc.suvida_id
    left join most_recent_bmi bmi
        on dp.suvida_id = bmi.suvida_id
    left join most_recent_bp bp
        on dp.suvida_id = bp.suvida_id
    left join most_recent_a1c_value a1c
        on dp.suvida_id = a1c.suvida_id
    left join most_recent_sdoh sdoh
        on dp.suvida_id = sdoh.suvida_id
    left join patient_history_measures phm
        on dp.suvida_id = phm.suvida_id
), quality_measures as (
    select
        pb.suvida_id,
        case
        -- Vaccinations
            when scl.quality_measure in ('Suvida - Flu Vaccine', 'Suvida - Pneumococcal Vaccine', 'Suvida - covid') then 'Vaccinations'
        -- Medication Adherence
            when scl.quality_measure in ('Med Adherence - Diabetes', 'Med Adherence - RAS', 'Med Adherence - Statins') then 'Medication Adherence'
        -- Quality of Care
            when scl.quality_measure in (
                'Annual Wellness Visit',
                'Care for Older Adults - Medication Review',
                'Care for Older Adults - Functional Status',
                'Breast Cancer Screening',
                'Colorectal Cancer Screening',
                'Controlling Blood Pressure',
                'Diabetes Care - Blood Sugar Controlled',
                'Diabetes Care - Eye Exam',
                'Diabetes Care - Kidney Disease Evaluation',
                'Suvida - Diabetic Foot Exam'
            ) then 'Quality of Care'
        -- Diagnostic Tests & Screenings (all others)
            else 'Diagnostic Tests & Screenings'
        end as category,
        scl.measure_skey,
        scl.quality_measure as measure_name,
        scl.evidence_array,
        case scl.quality_measure
            when 'Suvida - Thrombocytopenia' then combined_measure_status_desc
            when 'Suvida - Flu Vaccine' then bucket_1_desc
            when 'Suvida - covid' then bucket_1_desc
            when 'Suvida - Zoster' then combined_measure_status_desc
            when 'Suvida - Pneumococcal Vaccine' then bucket_1_desc
            when 'Care for Older Adults - Medication Review' then bucket_2_desc
            when 'Care for Older Adults - Functional Status' then bucket_2_desc
            when 'Care for Older Adults - Pain Assessment' then bucket_3_desc
            when 'Suvida - TDAP' then combined_measure_status_desc
            when 'Controlling Blood Pressure' then bucket_4_desc
            when 'Diabetes Care - Blood Sugar Controlled' then bucket_4_desc
            when 'suvida-echo' then case when bucket_1_desc like '%Coming%' then 'Pending' else bucket_1_desc end
            when 'suvida-spiro' then bucket_1_desc
            when 'Suvida - Creatinine' then combined_measure_status_desc
            when 'Suvida - Microalbumin' then combined_measure_status_desc
            when 'Suvida - eGFR' then bucket_5_desc
            when 'Diabetes Care - Kidney Disease Evaluation' then bucket_4_desc
            when 'Obesity Screening - BMI' then combined_measure_status_desc
            when 'Colorectal Cancer Screening' then combined_measure_status_desc
            when 'Breast Cancer Screening' then combined_measure_status_desc
            when 'Med Adherence - Diabetes' then bucket_4_desc
            when 'Med Adherence - RAS' then bucket_4_desc
            when 'Med Adherence - Statins' then bucket_4_desc
            when 'Osteoporosis Screening in Older Women' then combined_measure_status_desc
            when 'Suvida - Quantaflo' then bucket_1_desc
            when 'Suvida - PTH' then bucket_3_desc
            when 'Suvida - Diabetic Foot Exam' then bucket_1_desc
            when 'Diabetes Care - Eye Exam' then combined_measure_status_desc
            when 'Annual Wellness Visit' then bucket_2_desc
        end as measure_detail,
        current_quality_engine_status
    from patient_base pb
    left join summarized_care_logic scl
        on pb.suvida_id = scl.suvida_id
    where scl.quality_measure is not null
), additional_measures as (
    -- Unpivot the additional measures from patient_base
    select
        suvida_id,
        'Quality of Care' as category,
        null as measure_skey,
        'most_recent_BP' as measure_name,
        concat(Blood_pressure_text, '|', to_char(bp_creation_date)) as measure_detail,
        'Open' as current_quality_engine_status
    from patient_base
    where Blood_pressure_text is not null

    union all

    select
        suvida_id,
        'Quality of Care' as category,
        null as measure_skey,
        'most_recent_a1c_value' as measure_name,
        concat(to_char(a1c_value), '|', to_char(a1c_collected_date)) as measure_detail,
        'Open' as current_quality_engine_status
    from patient_base
    where a1c_value is not null

    union all

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'bmi' as measure_name,
        to_char(bmi) as measure_detail,
        'Open' as current_quality_engine_status
    from patient_base
    where bmi is not null

    union all

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'dementia_minicog' as measure_name,
        to_char(dementia_minicog) as measure_detail,
        'Open' as current_quality_engine_status
    from patient_base
    where dementia_minicog is not null

    union all

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'depression_phq2' as measure_name,
        to_char(depression_phq2) as measure_detail,
        'Open' as current_quality_engine_status
    from patient_base
    where depression_phq2 is not null

    union all

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'depression_phq9' as measure_name,
        to_char(depression_phq9) as measure_detail,
        'Open' as current_quality_engine_status
    from patient_base
    where depression_phq9 is not null

    union all

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'alcohol_auditc' as measure_name,
        to_char(alcohol_auditc) as measure_detail,
        iff(alcohol_auditc is not null, 'Closed', 'Open') as current_quality_engine_status
    from patient_base
    where alcohol_auditc is not null

    union all

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'SDoH_Screener' as measure_name,
        concat(to_char(SDOH_completed_past_12_months), ' | ', to_char(SDOH_Recent_Completion_Date)) as measure_detail,
        iff(SDOH_completed_past_12_months is not null, 'Closed', 'Open') as current_quality_engine_status
    from patient_base

    union all 

    select
        suvida_id,
        'Diagnostic Tests & Screenings' as category,
        null as measure_skey,
        'ROI_Screener' as measure_name,
        case 
            when roi_completed_past_12_months in ('Valid','Renewal Needed') then concat(roi_completed_past_12_months, ' | ',roi_Recent_Completion_Date) 
            else roi_completed_past_12_months 
        end as measure_detail,
        iff(roi_completed_past_12_months is not null, 'Closed', 'Open') as current_quality_engine_status
    from most_recent_roi
    
)
-- Unpivoted result: one row per suvida_id, measure_name
select
    suvida_id,
    category,
    measure_name,
    measure_skey,
    measure_detail,
    current_quality_engine_status,
    evidence_array
from quality_measures
where measure_detail is not null

union all

select
    suvida_id,
    category,
    measure_name,
    measure_skey,
    measure_detail,
    current_quality_engine_status,
    null as evidence_array
from additional_measures
    )
;


  