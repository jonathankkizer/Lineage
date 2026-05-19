
  
    

create or replace transient table dw_dev.dev_jkizer.patient_condition
    copy grants
    
    
    as (with time_period as (                                                                                                                                                                             
      select                                                                                                                                                                                        
          date_month as period_end_date,                                                                                                                                                            
          dateadd(year, -1, date_trunc(year, date_month)) as period_start_date                                                                                                                      
      from dw_dev.dev_jkizer.dim_date
      where is_bom = true                                                                                                                                                                           
      and date_day >= dateadd(month, -12, current_date())                                                                                                                                           
      and date_day <= current_date()                                                                                                                                                                
  ), cleaned_values as (                                                                                                                                                                            
      -- HCC diagnoses                                                                                                                                                                              
      select                                                                                                                                                                                        
          fhd.suvida_id, 
          'hcc' as source,
          tp.period_start_date,                                                                                                                                                                     
          tp.period_end_date,                                                                                                                                                                       
          date_trunc(month, tp.period_end_date) as period_month,                                                                                                                                    
          date(fhd.run_datetime) as run_date,                                                                                                                                                       
          fhd.period_type,                                                                                                                                                                          
          fhd.hcc_model,                                                                                                                                                                            
          fhd.icd_10_code,                                                                                                                                                                          
          fhd.icd_description,                                                                                                                                                                      
          cast(trim(fhd.hcc_code) as int) as hcc_code,                                                                                                                                              
          fhd.is_max_monthly_period                                                                                                                                                                 
      from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis fhd
      cross join time_period tp                                                                                                                                                                     
      where                                                                                                                                                                                         
          fhd.hcc_model = 28                                                                                                                                                                        
      and                                                                                                                                                                                           
          fhd.source_type = 'emr'                                                                                                                                                                   
      and                                                                                                                                                                                           
          date_trunc(month, fhd.period_end_date) between tp.period_start_date and tp.period_end_date                                                                                                
                                                                                                                                                                                                    
      union all                                                                                                                                                                                     
                                                                                                                                                                                                    
      -- Non-HCC diagnoses (from fct_diagnosis)                                                                                                                                                     
      select                                                                                                                                                                                        
          fd.suvida_id,             
          'icd' as source,
          tp.period_start_date,                                                                                                                                                                     
          tp.period_end_date,                                                                                                                                                                       
          date_trunc(month, tp.period_end_date) as period_month,                                                                                                                                    
          fd.diagnosis_date as run_date,                                                                                                                                                            
          null as period_type,                                                                                                                                                                      
          null as hcc_model,                                                                                                                                                                        
          fd.icd_10_code,                                                                                                                                                                           
          fd.icd_10_code_description as icd_description,                                                                                                                                            
          null as hcc_code,                                                                                                                                                                         
          null as is_max_monthly_period                                                                                                                                                             
      from dw_dev.dev_jkizer.fct_diagnosis fd
      cross join time_period tp                                                                                                                                                                     
      where                                                                                                                                                                                         
          (fd.source_type = 'emr')                                                                                                                                                                    
      and                                                                                                                                                                                           
          (date_trunc(month, fd.diagnosis_date) between tp.period_start_date and tp.period_end_date)
      and
        (lower(icd_10_code_description) ilike '%artificial knee joint%' or
        lower(icd_10_code_description) ilike '%artificial hip joint%'or
        lower(icd_10_code_description) ilike '%coronary artery bypass%' or
        lower(icd_10_code_description) ilike '%cabg%')
),
hr_icd_flags as (
    select
        period_start_date,
        period_end_date,
        period_month,
        period_type,
        suvida_id,
        case 
        -- chf (more specific - check first)
                when hcc_code in (224, 225, 226) and lower(icd_description) like '%(congestive)%' then 'Congestive Heart Failure'
        -- hf (broader - check second)
                when hcc_code between 224 and 226 and lower(icd_description) like '%heart failure%' then 'Heart Failure'
        -- esrd --> check first (most specific)
                when hcc_code in (226, 326) and lower(icd_description) like '%end stage renal disease%' 
                        then 'End Stage Renal Disease'     
        -- ckd --> check second (broader, excludes esrd)
                when hcc_code in (37, 226, 326, 327, 328, 329) and lower(icd_description) like '%chronic kidney disease%' and lower(icd_description) not like '%end stage renal disease%'
                        then 'Chronic Kidney Disease'
                when hcc_code in (279, 280) then 'COPD/Asthma'
                when hcc_code = 249 then 'Stroke'
                when hcc_code = 229 then 'Coronary Artery Disease'
                when hcc_code = 48 then 'Obesity'
                when hcc_code in (127, 136) then 'Dementia'    
                when hcc_code between 36 and 38 then 'Diabetes'           
                when hcc_code between 17 and 23 then 'Cancer'
        -- SUD
                when hcc_code between 135 and 138 then 'Substance Use Disorder'
        -- SMI
                when hcc_code between 151 and 154 then 'Serious Mental Illness' 

        -- Acute MI
                when hcc_code = 228 then 'Acute Myocardial Infarction'
        -- Pneumonia
                when hcc_code = 282 then 'Aspiration and Specified Bacterial Pneumonias'
        -- Knee Replacement
                when lower(trim(icd_description)) like '%artificial knee joint%' then 'Knee Replacement (TKA)'
        -- Hip Replacement
                when lower(trim(icd_description)) like '%artificial hip joint%' then 'Hip Replacement (THA)'
        -- CABG
                when lower(trim(icd_description)) like '%coronary artery bypass%' or lower(trim(icd_description)) like '%cabg%' then 'Coronary artery bypass graft (CABG)'
                        else null end as condition_type,
        case 
                when hcc_code in (37, 226, 326, 327, 328, 329) and lower(icd_description) like '%chronic kidney disease%' then
                    case 
                        when lower(icd_description) like '%stage 3a%' then 'Stage 3a'
                        when lower(icd_description) like '%stage 3b%' then 'Stage 3b'
                        when lower(icd_description) like '%stage 3 unspecified%' then 'Stage 3 Unspecified'
                        when lower(icd_description) like '%stage 4%' then 'Stage 4'
                        when lower(icd_description) like '%stage 5%' then 'Stage 5'
                        when lower(icd_description) like '%stage 1%' or lower(icd_description) like '%stage 2%' then 'Stage 1-2'
                                else null end
                                        else null
                                                end as ckd_stage_detail,
        case
        -- hf
                when hcc_code between 224 and 225 then True
                when hcc_code = 226 and lower(icd_description) like '%heart failure%' then True
        -- chf
                when hcc_code = 226 and lower(icd_description) like '%(congestive) heart failure%' then True
                when hcc_code in (224, 225) then True
        -- ckd
                when hcc_code in (37, 327, 328, 329, 326) then True
                when hcc_code = 226 and lower(icd_description) like '%chronic kidney disease%' then True
        -- COPD/asthma
                when hcc_code in (279, 280) then True
        -- stroke
                when hcc_code = 249 then True
        -- CAD
                when hcc_code = 229 then True
        -- obesity
                when hcc_code = 48 then True
        --dementia
                when hcc_code in (127, 136) then True
        -- diabetes
                when hcc_code between 36 and 38 then True
        -- esrd
                when hcc_Code = 326 then True
        -- cancer
                when hcc_code between 17 and 23 then True
        -- SUD
                when hcc_code between 135 and 138 then True
        -- SMI
                when hcc_code between 151 and 154 then True
        -- Acute MI
                when hcc_code = 228 then True
        -- Pneumonia
                when hcc_code = 282 then True
        -- Knees and Hips
                when lower(trim(icd_description)) like '%artificial knee joint%' then True                                                                                                                     
                when lower(trim(icd_description)) like '%artificial hip joint%' then True       
        -- CABG
                when lower(trim(icd_description)) like '%coronary artery bypass%' or lower(trim(icd_description)) like '%cabg%' then True
                    else False
                        end as is_active_condition
    from cleaned_values 
    qualify row_number() over(partition by suvida_id, period_month, condition_type order by period_start_date desc) = 1
),
-- Determine polychronic eligibility at patient-month level
polychronic_patients as (
    select
        suvida_id,
        period_month,
        period_start_date,
        period_end_date,
        period_type,
    from hr_icd_flags
    where is_active_condition = True
    group by suvida_id, period_month, period_start_date, period_end_date, period_type
    having 
        max(case when condition_type = 'Heart Failure' then 1 else 0 end) = 1 and 
        max(case when condition_type = 'Diabetes' then 1 else 0 end) = 1 and
        max(case when condition_type = 'Chronic Kidney Disease' then 1 else 0 end) = 1
),
final_flags as (
    -- Regular conditions with formatting
    select 
        period_start_date,
        period_end_date,
        period_month,
        period_type,
        suvida_id, 
        case 
           when condition_type = 'Chronic Kidney Disease' and ckd_stage_detail is not null 
                then condition_type || ': ' || ckd_stage_detail  
           when condition_type = 'Substance Use Disorder' or condition_type = 'Serious Mental Illness' 
                then 'SUD-SMI' 
           else condition_type 
        end as condition_type,
        case 
            when (condition_type = 'Substance Use Disorder' and is_active_condition = True) 
                or (condition_type = 'Serious Mental Illness' and is_active_condition = True)
            then True 
            else is_active_condition 
        end as is_active_condition
    from hr_icd_flags
    where is_active_condition = True
    
    UNION ALL
    
    -- Add polychronic flag as its own condition
    select
        period_start_date,
        period_end_date,
        period_month,
        period_type,
        suvida_id,
        'Polychronic' as condition_type,
        True as is_active_condition
    from polychronic_patients
)
select
    period_start_date,
    period_end_date,
    period_month,
    period_type,
    suvida_id,
    condition_type,
    is_active_condition,
    case
        when condition_type in ('End Stage Renal Disease', 'Cancer', 'Dementia', 'SUD-SMI') then True else False end as is_active_focus_condition
from final_flags
    )
;


  