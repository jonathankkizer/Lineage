
  
    

create or replace transient table dw_dev.dev_jkizer.patient_huddle
    copy grants
    
    
    as (/* 
Note on behavior of min/max in SELECT -- use max() if else value is a null; if else value is 'Open', use min() 
*/

with current_payer_quality as (
    select
        pma.suvida_id,
        pma.quality_measure,
        concat('Next Refill:',pma.NEXT_REFILL_DUE, '|','PDC:', pma.PERC_DAYS_COVERED, '|', 'GDR:',pma.GAP_DAYS_REMAINING, '|', pma.RX_NAME) as "measure_detail",
        pma.measure_status,
        pma.measure_numerator,
        pma.PERC_DAYS_COVERED as "pdc",
        pma.GAP_DAYS_REMAINING as "gap_days",
        pma.NEXT_REFILL_DUE  as "next_refill_date",
        pma.RX_NAME  as "medication_name"
    from dw_dev.dev_jkizer.patient_med_adherence pma
    where pma.is_measure_year_current_report = 'TRUE'
    and year(measure_year) = year(current_date())
    union
    select 
        pqm.suvida_id,
        pqm.quality_measure,
        pqm.measure_detail,
        pqm.measure_status,
        pqm.measure_numerator,
        null as "pdc",
        null as "gap_days",
        null as "next_refill_date",
        null as "medication_name"
    from dw_dev.dev_jkizer.patient_quality_measure pqm 
    where pqm.is_measure_year_current_report = 1
    and year(measure_year) = year(current_date())
    and pqm.quality_measure not like 'Med%'
), care_logic as (
    select 
        coalesce(pq.suvida_id, ssl.suvida_id) as suvida_id,
        coalesce(pq.quality_measure, ssl.quality_measure) as quality_measure,
        pq.measure_status as payer_measure_status,
        pq.measure_detail as payer_measure_detail,
        ssl.suvida_measure_status,
        ssl.evidence_desc as suvida_measure_detail,
        ssl.evidence_date as suvida_evidence_date,
        case 
          when greatest_ignore_nulls(ssl.suvida_numerator, pq.measure_numerator) = 1 then 'Closed'
          when greatest_ignore_nulls(ssl.suvida_numerator, pq.measure_numerator) != 1 and ssl.pending_numerator = 1 then 'Coming Up'
          when greatest_ignore_nulls(ssl.suvida_numerator, pq.measure_numerator) != 1 and (ssl.pending_numerator != 1 or ssl.pending_numerator is null) then 'Open'
      end as combined_measure_status,
        concat('Payer: ', pq.measure_status, ' ', coalesce(pq.measure_detail, 'No Detail Available')) as payer_logic_desc,
        concat('Suvida: ', ssl.suvida_measure_status, ' ', ssl.evidence_desc, ' ', evidence_date) as suvida_care_logic_desc,
    from current_payer_quality pq
    full outer join dw_dev.dev_jkizer_quality.stars_suvida_logic ssl
        on pq.suvida_id = ssl.suvida_id
        and pq.quality_measure = ssl.quality_measure
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
        concat(combined_measure_status, ' | ', suvida_measure_detail) as bucket_3_desc, -- note this doesn't just pass the value; if we need to do that, we have to go back to stars suvida structure and differentiate between value and CPTs at that level
        payer_logic_desc as bucket_4_desc,
        TRIM(suvida_measure_detail) as bucket_5_desc
    from care_logic 
)
select
    dp.suvida_id,
    max(iff(scl.quality_measure = 'Suvida - Thrombocytopenia', 
            combined_measure_status_desc, 
            null)) 
    as thrombocytopenia_detail,
    min(iff(scl.quality_measure = 'Suvida - Flu Vaccine', 
            bucket_1_desc, 
            'Missing')) 
    as flu_detail,
    min(iff(scl.quality_measure = 'Suvida - covid', 
            bucket_1_desc, 
            'Missing')) 
    as covid_detail,
    min(case
            when scl.quality_measure = 'Suvida - Zoster' then combined_measure_status_desc
            when scl.quality_measure != 'Suvida - Zoster' and dp.age_year > 50 then 'Missing'
            when scl.quality_measure is null and dp.age_year > 50 then 'Missing'
    end) 
    as zoster_detail,
    min(case
            when scl.quality_measure = 'Suvida - Pneumococcal Vaccine'  then bucket_1_desc
            when scl.quality_measure != 'Suvida - Pneumococcal Vaccine' and dp.age_year >= 50 then 'Missing'
            when scl.quality_measure is null and  dp.age_year >= 50 then 'Missing'
    end) as pneumo_detail,
    min(case
            when scl.quality_measure = 'Care for Older Adults - Medication Review'  then bucket_2_desc
            when scl.quality_measure != 'Care for Older Adults - Medication Review' and dp.age_year >= 66 then 'Open'
            when scl.quality_measure is null and  dp.age_year >= 66 then 'Open'
    end) as med_review_detail,
    min(case
            when scl.quality_measure = 'Care for Older Adults - Functional Status'  then bucket_2_desc
            when scl.quality_measure != 'Care for Older Adults - Functional Status' and dp.age_year >= 66 then 'Open'
            when scl.quality_measure is null and  dp.age_year >= 66 then 'Open'
    end) as functional_status_detail,
    min(case
            when scl.quality_measure = 'Care for Older Adults - Pain Assessment'  then bucket_3_desc
            when scl.quality_measure != 'Care for Older Adults - Pain Assessment' and dp.age_year >= 66 then 'Open'
            when scl.quality_measure is null and  dp.age_year >= 66 then 'Open'
    end) as pain_assessment_detail,
    min(iff(scl.quality_measure = 'Suvida - TDAP', 
            combined_measure_status_desc, 
            'Open')) 
    as tdap_detail,
    max(iff (scl.quality_measure = 'Controlling Blood Pressure',
        bucket_4_desc,
        null))
    as bp_detail,
    max(iff (scl.quality_measure = 'Diabetes Care - Blood Sugar Controlled',
        bucket_4_desc,
        null))
    as a1c_detail,
    min(iff(scl.quality_measure = 'suvida-echo', 
        bucket_1_desc, 
        'Missing'))
    as echo_detail,
    max(iff(scl.quality_measure = 'suvida-spiro', 
        bucket_1_desc, 
        null)) 
    as spiro_detail,
    min(case
            when scl.quality_measure = 'Suvida - Creatinine'
                and (hcc.diabetes_cc_flag = 1 or hcc.diabetes_non_cc_flag = 1) then combined_measure_status_desc
            when scl.quality_measure != 'Suvida - Creatinine'
                and (hcc.diabetes_cc_flag = 1 or hcc.diabetes_non_cc_flag = 1) then 'Open'
    end) as creatinine_detail,
    min(case
            when scl.quality_measure = 'Suvida - Microalbumin'
                and (hcc.diabetes_cc_flag = 1 or hcc.diabetes_non_cc_flag = 1) then combined_measure_status_desc
            when scl.quality_measure != 'Suvida - Microalbumin'
                and (hcc.diabetes_cc_flag = 1 or hcc.diabetes_non_cc_flag = 1) then 'Open'
    end) as microalbumin_detail,
    max(iff(scl.quality_measure = 'Suvida - eGFR', 
        bucket_5_desc,
        null)) as egfr_detail,
    max(iff(scl.quality_measure = 'Diabetes Care - Kidney Disease Evaluation',
        bucket_4_desc,
        null)) as kidney_disease_evaluation_detail,
    min(iff(scl.quality_measure = 'Obesity Screening - BMI', 
            combined_measure_status_desc, 
            'Open')) 
    as bmi_detail,
    max(iff(scl.quality_measure = 'Colorectal Cancer Screening', 
            combined_measure_status_desc, 
            null)) 
    as ccs_detail,
    max(iff(scl.quality_measure = 'Breast Cancer Screening', 
            combined_measure_status_desc, 
            null)) 
    as bcs_detail,
    max(iff(scl.quality_measure = 'Med Adherence - Diabetes', 
            bucket_4_desc, 
            null)) 
    as med_adherence_diabetes_detail,
    max(iff(scl.quality_measure = 'Med Adherence - RAS', 
            bucket_4_desc, 
            null)) 
    as med_adherence_ras_detail,
    max(iff(scl.quality_measure = 'Med Adherence - Statins', 
            bucket_4_desc, 
            null)) 
    as med_adherence_statin_detail,
    max(iff(scl.quality_measure = 'Osteoporosis Screening in Older Women', 
            combined_measure_status_desc, 
            null)) 
    as osteo_screening_detail,
    max(iff(scl.quality_measure = 'Suvida - Quantaflo', 
            bucket_1_desc, 
            null)) 
    as quantaflo_detail,
    max(iff(scl.quality_measure = 'Suvida - PTH', 
        bucket_3_desc, 
        null)) 
    as pth_detail,
    -- pth_detail -- need clarity on purpose/logic for this one
    min(case
            when scl.quality_measure = 'Suvida - Diabetic Foot Exam'
                and (hcc.diabetes_cc_flag = 1 or hcc.diabetes_non_cc_flag = 1) then bucket_1_desc
            when scl.quality_measure != 'Suvida - Diabetic Foot Exam'
                and (hcc.diabetes_cc_flag = 1 or hcc.diabetes_non_cc_flag = 1) then 'Missing'
    end) as diabetic_foot_exam_detail,
    max(iff(scl.quality_measure = 'Diabetes Care - Eye Exam',
            combined_measure_status_desc,
            null)) 
    as diabetic_retinal_exam_detail,
    min(iff(scl.quality_measure = 'Annual Wellness Visit', 
            bucket_2_desc, 
            'Open')) 
    as awv_detail,
from dw_dev.dev_jkizer.dim_patient dp
left join dw_dev.dev_jkizer.patient_hcc_diagnosis hcc
    on dp.suvida_id = hcc.suvida_id
left join summarized_care_logic scl 
    on dp.suvida_id = scl.suvida_id
group by dp.suvida_id
    )
;


  