
  
    

create or replace transient table dw_dev.dev_jkizer.patient_monthly_condition
    copy grants
    
    
    as (with pivoted_conditions as (
    select
        suvida_id,
        period_start_date,
        period_end_date,
        period_month,

        -- Boolean columns for each condition
        max(case when condition_type = 'Polychronic' then true else false end) as is_poly_chronic,
        max(case when condition_type = 'Congestive Heart Failure' then true else false end) as is_congestive_heart_failure,
        max(case when condition_type = 'Heart Failure' then true else false end) as is_heart_failure,
        max(case when condition_type = 'End Stage Renal Disease' then true else false end) as is_esrd,

        -- CKD stage columns (check both condition_type AND ckd_stage_detail)
        max(case when condition_type= 'Chronic Kidney Disease' then true else false end) as is_ckd,
        max(case when condition_type = 'Chronic Kidney Disease: Stage 1-2' then true else false end) as is_ckd_stage_1_2,
        max(case when condition_type = 'Chronic Kidney Disease: Stage 3a' then true else false end) as is_ckd_stage_3a,
        max(case when condition_type = 'Chronic Kidney Disease: Stage 3b' then true else false end) as is_ckd_stage_3b,
        max(case when condition_type = 'Chronic Kidney Disease: Stage 3 Unspecified' then true else false end) as is_ckd_stage_3_unspecified,
        max(case when condition_type = 'Chronic Kidney Disease: Stage 4' then true else false end) as is_ckd_stage_4,
        max(case when condition_type = 'Chronic Kidney Disease: Stage 5' then true else false end) as is_ckd_stage_5,

        max(case when condition_type = 'COPD/Asthma' then true else false end) as is_copd_asthma,
        max(case when condition_type = 'Stroke' then true else false end) as is_stroke,
        max(case when condition_type = 'Coronary Artery Disease' then true else false end) as is_coronary_artery_disease,
        max(case when condition_type = 'Obesity' then true else false end) as is_obesity,
        max(case when condition_type = 'Dementia' then true else false end) as is_dementia,
        max(case when condition_type = 'Diabetes' then true else false end) as is_diabetes,
        max(case when condition_type = 'Cancer' then true else false end) as is_cancer,
        max(case when condition_type = 'SUD-SMI' then true else false end) as is_sud_smi,
        max(case when condition_type = 'Acute Myocardial Infarction' then true else false end) as is_acute_mi,
        max(case when condition_type = 'Aspiration and Specified Bacterial Pneumonias' then true else false end) as is_pneumonia,
        max(case when condition_type = 'Coronary artery bypass graft (CABG)' then true else false end) as is_cabg,
        max(case when condition_type = 'Hip Replacement (THA)' then true else false end) as is_hip_replacement,
        max(case when condition_type = 'Knee Replacement (TKA)' then true else false end) as is_knee_replacement,

        -- Aggregate pipe-delimited column
        nullif(listagg(distinct condition_type, ' | ') within group (order by condition_type), '') as active_conditions,

        max(case when condition_type like '%Chronic Kidney Disease%' then True else False end) as has_ckd

    from dw_dev.dev_jkizer.patient_condition
    group by suvida_id, period_start_date, period_end_date, period_month
)
select
    suvida_id,
    period_start_date,
    period_end_date,
    period_month,
    iff(period_month = date_trunc('month', current_date()), true, false) as is_current_month,

    -- All boolean condition columns
    is_congestive_heart_failure,
    is_esrd,
    is_heart_failure,
    is_diabetes,
    is_ckd,
    is_ckd_stage_3a,
    is_ckd_stage_3b,
    is_ckd_stage_3_unspecified,
    is_ckd_stage_4,
    is_ckd_stage_5,
    is_ckd_stage_1_2,
    is_poly_chronic,
    is_copd_asthma,
    is_stroke,
    is_coronary_artery_disease,
    is_obesity,
    is_dementia,
    is_cancer,
    is_sud_smi,
    is_acute_mi,
    is_pneumonia,
    is_cabg,
    is_hip_replacement,
    is_knee_replacement,

    -- Aggregate columns
    active_conditions,

    -- Suvida focus conditions aggregate
    nullif(
        array_to_string(
            array_compact(
                array_construct(
                    case when is_poly_chronic then 'Polychronic' else null end,
                    case when is_dementia then 'Dementia' else null end,
                    case when is_cancer then 'Cancer' else null end,
                    case when is_esrd then 'End Stage Renal Disease' else null end,
                    case when is_sud_smi then 'SUD-SMI' else null end
                )
            ),
            ' | '
        ),
        ''
    ) as active_suvida_focus_conditions

from pivoted_conditions
    )
;


  