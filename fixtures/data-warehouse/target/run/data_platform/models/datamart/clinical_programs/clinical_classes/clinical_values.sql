
  
    

create or replace transient table dw_dev.dev_jkizer.clinical_values
    copy grants
    
    
    as (with values_unioned as (

-- Hemoglobin A1c
select
      flr.suvida_id,
      flr.collected_date as value_date,
      'Hemoglobin A1c'  as value_type,
      flr.numeric_test_value as value
  from dw_dev.dev_jkizer.fct_lab_result flr
  where test_name in ('HEMOGLOBIN A1C', 'Hemoglobin A1c', 'HEMOGLOBIN A1c')
  and flr.numeric_test_value is not null

  union all

-- Systolic BP  
  select
      fv.suvida_id,
      date(fv.creation_datetime) as value_date,
      'Systolic BP' as value_type,
      fv.blood_pressure_systolic as value
  from dw_dev.dev_jkizer.fct_vital fv
  where fv.blood_pressure_systolic is not null

  union all

-- Pre/Post TUG, Pre/Post Chair Stand, GAD-7/PHQ-9
  select
    suvida_id,
    test_date as value_date,
    test_type as value_type,
    test_value_numeric as value
from dw_dev.dev_jkizer.patient_clinical_assessment pca
where (test_type in ('GAD-7', 'PHQ-9', 'Pre-Chair-Stand', 'Post-Chair-Stand', 'Pre-TUG', 'Post-TUG'))
and (test_value_numeric is not null)
)

select 
   *
from values_unioned
    )
;


  