
  
    

create or replace transient table dw_dev.dev_jkizer.suspect_ckd
    copy grants
    
    
    as (

with last_2_readings as (
-- per AMP logic, grab the lowest 2 readings 90 days apart (all-time) that are CONSECUTIVE 
  with base_data as (
      select
          suvida_id,
          report_id,
          test_category,
          numeric_test_value,
          collected_date,
          collected_date_time,
          lag(collected_date) over (partition by suvida_id order by collected_date asc) as prev_collected_date,
          lag(numeric_test_value) over (partition by suvida_id order by collected_date asc) as prev_test_value,
          lag(report_id) over (partition by suvida_id order by collected_date asc) as prev_report_id
      from dw_dev.dev_jkizer.fct_lab_result
      where lower(test_name) ilike '%egfr%'
  ),
  consecutive_pairs as (
      select
          suvida_id,
          prev_report_id as first_report_id,
          report_id as second_report_id,
          prev_test_value as first_test_value,
          numeric_test_value as second_test_value,
          prev_collected_date as first_collected_date,
          collected_date as second_collected_date,
          collected_date - prev_collected_date as days_apart
      from base_data
      where prev_test_value is not null
          and prev_test_value < 60
          and numeric_test_value < 60
          and collected_date - prev_collected_date >= 90
  ),
  ranked_pairs as (
      select
          *,
          row_number() over (
              partition by suvida_id
              order by first_test_value asc, second_test_value asc, first_collected_date asc
          ) as rn
      from consecutive_pairs
  )

  select
      suvida_id,
      first_report_id,
      second_report_id,
      first_test_value,
      second_test_value,
      first_collected_date,
      second_collected_date,
      days_apart
  from ranked_pairs
  where rn = 1
),

readings_below_threshold as (
    select
        suvida_id,
        greatest(first_test_value, second_test_value) as highest_test_value,
        array_agg(
            object_construct(
                'diagnosis_note', 
                concat('Suspected diagnosis based on eGFR values from patient chart: ', 
                    first_collected_date::string, ' = ', first_test_value::string, 
                    ' and ', second_collected_date::string, ' = ', second_test_value::string)
            )
        ) as last_2_readings
    from last_2_readings
    group by suvida_id, greatest(first_test_value, second_test_value)
), 

patients_already_diagnosed_ckd as (
-- use to exclude patients in later CTEs, use HCC model V28
--- Stage 5 --- HCC326
--- Stage 4 --- HCC327
-- "Chronic Kidney Disease, Moderate (Stage 3b)" --- HCC328
-- "Chronic Kidney Disease, Moderate (Stage 3, Except 3B)" --- HCC329
    select
        hd.suvida_id,
        array_agg(distinct hcc_code) as hcc_codes
    from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd
	where hd.period_type = 'monthly' and hd.hcc_model = 28
	and hd.is_max_monthly_period = 1 and hd.hcc_code in ('326', '327', '328', '329')
    group by suvida_id
)

select
    r.suvida_id,
    case
        when highest_test_value between 45 and 59
            and (padc.suvida_id is null or not arrays_overlap(padc.hcc_codes, array_construct('329', '328', '327', '326')))
            then 'N1831'
        when highest_test_value between 29 and 44
            and (padc.suvida_id is null or not arrays_overlap(padc.hcc_codes, array_construct('328', '327', '326')))
            then 'N1832'
        when highest_test_value between 15 and 28
            and (padc.suvida_id is null or not arrays_overlap(padc.hcc_codes, array_construct('327', '326')))
            then 'N184'
        when highest_test_value < 15
            and (padc.suvida_id is null or not arrays_overlap(padc.hcc_codes, array_construct('326')))
            then 'N185'
    end as suspect_icd_10_code,
    highest_test_value,
    last_2_readings
from readings_below_threshold r
left join patients_already_diagnosed_ckd padc
    on padc.suvida_id = r.suvida_id
where suspect_icd_10_code is not null
    )
;


  