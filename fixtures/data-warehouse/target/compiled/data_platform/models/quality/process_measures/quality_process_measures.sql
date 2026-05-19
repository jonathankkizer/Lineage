with quality_measures as (

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.breast_cancer_screening

    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.care_for_older_adults_functional_status
    
    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.care_for_older_adults_medication_review
    
    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.colorectal_cancer_screening
    
    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.controlling_blood_pressure
    
    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.diabetes_care_blood_sugar_controlled_a1c
    
    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.diabetes_care_eye_exam

    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.diabetes_care_kidney_disease_evaluation

    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.osteoporosis_management_women_who_had_fx

    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.pcp_office_visit
    
    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, null as med_adherence_gap_status, quality_engine_info_array, null as progress_bar  
    from dw_dev.dev_jkizer_quality.zephyr

    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, med_adherence_gap_status, quality_engine_info_array, progress_bar
    from dw_dev.dev_jkizer_quality.med_adherence_diabetes

    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, med_adherence_gap_status, quality_engine_info_array, progress_bar
    from dw_dev.dev_jkizer_quality.med_adherence_ras

    union all
    
    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, med_adherence_gap_status, quality_engine_info_array, progress_bar
    from dw_dev.dev_jkizer_quality.med_adherence_statins

    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.statin_therapy_for_cardio_disease

    union all

    select suvida_id, quality_measure, stage, gap_status, stage_name, evidence_desc, evidence_date, measure_year, 
    latest_rank_overall, med_adherence_gap_status, quality_engine_info_array, null as progress_bar 
    from dw_dev.dev_jkizer_quality.statin_use_in_persons_with_diabetes
)

select * from quality_measures