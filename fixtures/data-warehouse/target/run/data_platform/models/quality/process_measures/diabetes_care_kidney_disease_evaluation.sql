
  
    

create or replace transient table dw_dev.dev_jkizer_quality.diabetes_care_kidney_disease_evaluation
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
        and quality_measure = 'Diabetes Care - Kidney Disease Evaluation'
        and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)
, stage_two as (
    select 
        year(creation_date_time) as measure_year,
        suvida_id, 
        'Diabetes Care - Kidney Disease Evaluation' as quality_measure, 
        '2' as stage, 
        'Open' as gap_status, 
        'Order Placed' as stage_name, 
        date(creation_date) as evidence_date, 
        order_test_name as evidence_desc,
        object_construct(
            'id', report_id,
            'elation_object', 'Lab Order',
            'evidence_date', date(creation_date_time),
            'evidence_string', order_test_name,
            'evidence_description', concat('Order Placed for ',order_test_name,' on ', to_varchar(creation_date_time, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_order
    where lower(order_test_name) like '%kidney%'
      and order_state = 'outstanding'
)

, unified as (
    select distinct suvida_id, 
        lab_result_skey, 
        date(collected_date) as collected_date, 
        null as encounter_date, 
        test_name, 
        test_category, 
        null as cpt_code,
        null as procedure_skey
    from dw_dev.dev_jkizer.fct_lab_result
    where (
            lower(test_name) like '%egfr%' 
            or lower(test_category) in ('albumin/creatinine ratio,urine', 'albumin, random urine w/creatinine')
          )
      and numeric_test_value is not null  

    union all

    select distinct suvida_id, 
        null as lab_result_skey, 
        null as collected_date, 
        date(encounter_date) as encounter_date, 
        null as test_name, 
        null as test_category, 
        cpt_code, 
        procedure_skey
    from dw_dev.dev_jkizer.fct_procedure
    where cpt_code in ('80047','80048','80050','80053','80069','82565','82043','82570')
) 

, all_signals as (
  select
    suvida_id,
    year(greatest(coalesce(collected_date, encounter_date))) as measure_year,

    max(case when lower(test_name) like '%egfr%' then 1 else 0 end) as has_egfr_lab,
    max(case when lower(test_name) like '%egfr%' then date(collected_date) else null end) as max_egfr_date,
    max_by(lab_result_skey,case when lower(test_name) like '%egfr%' then collected_date else null end) as egfr_lab_result_skey,

    max(case when lower(test_category) in ('albumin/creatinine ratio,urine', 'albumin, random urine w/creatinine') then 1 else 0 end) as has_uacr_lab,
    max(case when lower(test_category) in ('albumin/creatinine ratio,urine', 'albumin, random urine w/creatinine') then date(collected_date) else null end) as max_uacr_date,
    max_by(lab_result_skey,case when lower(test_category) in ('albumin/creatinine ratio,urine', 'albumin, random urine w/creatinine') then collected_date else null end) as uacr_lab_result_skey,

    max(case when cpt_code in ('80047','80048','80050','80053','80069','82565') then 1 else 0 end) as has_egfr_cpt,
    max(case when cpt_code in ('80047','80048','80050','80053','80069','82565') then date(encounter_date) else null end) as max_egfr_cpt_date,
    max_by(procedure_skey,case when cpt_code in ('80047','80048','80050','80053','80069','82565') then encounter_date else null end) as egfr_cpt_procedure_skey,

    max(case when cpt_code = '82043' then 1 else 0 end) as has_albumin_cpt,
    max(case when cpt_code = '82043' then date(encounter_date) else null end) as max_albumin_cpt_date,
    max_by(procedure_skey,case when cpt_code = '82043' then encounter_date else null end) as albumin_cpt_procedure_skey,

    max(case when cpt_code = '82570' then 1 else 0 end) as has_creatinine_cpt,
    max(case when cpt_code = '82570' then date(encounter_date) else null end) as max_creatinine_cpt_date,
    max_by(procedure_skey,case when cpt_code = '82570' then encounter_date else null end) as creatinine_cpt_procedure_skey

  from unified
  group by suvida_id, year(greatest(coalesce(collected_date, encounter_date))) 
)

, stage_three_a as (
    select 
        year(egfr.collected_date) as measure_year,
        egfr.suvida_id, 
        'Diabetes Care - Kidney Disease Evaluation' as quality_measure, 
        '3' as stage,
        'Open' as gap_status,
        'eGFR Done - Missing uACR' as stage_name,
        date(egfr.collected_date) as evidence_date, 
        concat(egfr.test_name, ' Resulted Value: ', egfr.test_value) as evidence_desc,
        object_construct(
            'id', egfr.report_id,
            'elation_object', 'Report',
            'evidence_date', date(egfr.collected_date),
            'evidence_string', concat('Test Name: ',egfr.test_name,'. Test Result: ', egfr.test_value),
            'evidence_description', concat('eGFR done on ', to_varchar(collected_date, 'MM/DD/YYYY'),': ',test_name,', but missing uACR')
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_result egfr
    join all_signals s
        on egfr.suvida_id = s.suvida_id
       and egfr.lab_result_skey = s.egfr_lab_result_skey
    where s.has_egfr_lab = 1
      and s.has_uacr_lab = 0
)

, stage_three_b as (
    select 
        year(acr.collected_date) as measure_year,
        acr.suvida_id, 
        'Diabetes Care - Kidney Disease Evaluation' as quality_measure, 
        '3' as stage,
        'Open' as gap_status,
        'uACR Done - Missing eGFR ' as stage_name,
        date(acr.collected_date) as evidence_date, 
        concat(acr.test_name, ' Resulted Value: ', acr.test_value) as evidence_desc,
        object_construct(
            'id', acr.report_id,
            'elation_object', 'Report',
            'evidence_date', date(acr.collected_date),
            'evidence_string', concat('Test Name: ',acr.test_name,'. Test Result: ', acr.test_value),
            'evidence_description', concat('uACR Done on ', to_varchar(acr.collected_date, 'MM/DD/YYYY'),': ',acr.test_name,', but missing eGFR')
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_lab_result acr
    join all_signals s
        on acr.suvida_id = s.suvida_id
       and acr.lab_result_skey = s.uacr_lab_result_skey
    where s.has_egfr_lab = 0
      and s.has_uacr_lab = 1
)

, stage_four as ( 
    select 
        sig.measure_year,
        sig.suvida_id, 
        'Diabetes Care - Kidney Disease Evaluation' as quality_measure, 
        '4' as stage,
        'Pending' as gap_status,
        'Suvida Closed' as stage_name,
        date(case
            when sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1 
            then greatest(el.collected_date, ul.collected_date)
            else greatest(ec.encounter_date,greatest(ac.encounter_date, cr.encounter_date))
        end) as evidence_date,
        case
            when sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1
            then concat('eGFR: ', el.test_name, ' – ', el.test_value,
                        ' | uACR: ', ul.test_name, ' – ', ul.test_value)
            else concat('eGFR CPT: ', ec.cpt_code,
                        ' | albumin CPT: ', ac.cpt_code,
                        ' | creatinine CPT: ', cr.cpt_code)
        end as evidence_desc,
        object_construct(
            'id', coalesce(el.report_id, ul.report_id),
            'elation_object', 'Report',
            'evidence_date', date(case
                when sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1 
                then greatest(el.collected_date, ul.collected_date)
                else greatest(ec.encounter_date,greatest(ac.encounter_date, cr.encounter_date))
                end),
            'evidence_string', case
                when sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1
                then concat('eGFR: ', el.test_name, ' – ', el.test_value,
                        ' | uACR: ', ul.test_name, ' – ', ul.test_value)
                else concat('eGFR CPT: ', ec.cpt_code,
                        ' | albumin CPT: ', ac.cpt_code,
                        ' | creatinine CPT: ', cr.cpt_code)
                end,
            'evidence_description', concat('Suvida Closed on ', to_varchar(case
                when sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1 
                then greatest(el.collected_date, ul.collected_date)
                else greatest(ec.encounter_date,greatest(ac.encounter_date, cr.encounter_date))
                end, 'MM/DD/YYYY')
                ,': ',case
                when sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1
                then concat('eGFR: ', el.test_name, ' – ', el.test_value,
                        ' | uACR: ', ul.test_name, ' – ', ul.test_value)
                else concat('eGFR CPT: ', ec.cpt_code,
                        ' | albumin CPT: ', ac.cpt_code,
                        ' | creatinine CPT: ', cr.cpt_code)
                end)
        ) as quality_engine_info_array
    from all_signals sig
    left join dw_dev.dev_jkizer.fct_lab_result el
        on el.lab_result_skey = sig.egfr_lab_result_skey
    left join dw_dev.dev_jkizer.fct_lab_result ul
        on ul.lab_result_skey = sig.uacr_lab_result_skey
    left join dw_dev.dev_jkizer.fct_procedure ec
        on ec.procedure_skey = sig.egfr_cpt_procedure_skey
    left join dw_dev.dev_jkizer.fct_procedure ac
        on ac.procedure_skey = sig.albumin_cpt_procedure_skey
    left join dw_dev.dev_jkizer.fct_procedure cr
        on cr.procedure_skey = sig.creatinine_cpt_procedure_skey
    where (sig.has_egfr_lab = 1 and sig.has_uacr_lab = 1)
       or (sig.has_egfr_cpt = 1 and sig.has_albumin_cpt = 1 and sig.has_creatinine_cpt = 1)
)

, stage_five as (
    select 
        year(last_modified_datetime) as measure_year,
        suvida_id,
        quality_measure,
        '5' as stage,
        'Pending' as gap_status,
        'Supplemental Data Submitted' as stage_name,
        workflow_status_detail as evidence_desc,
        date(last_modified_datetime) as evidence_date,
        object_construct(
            'id',quality_measure_skey ,
            'suvida_object', 'workflow_quality_stars',
            'evidence_date', date(last_modified_datetime), 
            'evidence_string', workflow_note,
            'evidence_description', concat('Supplemental data submitted on ', to_varchar(last_modified_datetime, 'MM/DD/YYYY'))
        ) as quality_engine_info_array
    from dw_dev.dev_jkizer.workflow_quality_stars
    where quality_measure = 'Diabetes Care - Kidney Disease Evaluation'
      and workflow_status_detail = 'Submitted - Pending Payer Audit'
      and workflow_status_index = 1
      and is_automated_activity = false
)
, stage_six as (
   select 
        year(measure_year) as measure_year, 
        suvida_id, 
        quality_measure, 
        '6' as stage, 
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
      and quality_measure = 'Diabetes Care - Kidney Disease Evaluation'
      and measure_year_report_rank = 1
    qualify row_number() over (
        partition by suvida_id, year(measure_year)
        order by report_date asc
    ) = 1
)	

, combined_data as (
    select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_one
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_two
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_a
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_three_b
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_four
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_five
    union all select suvida_id, evidence_date, evidence_desc, quality_measure, stage, gap_status, stage_name, measure_year, quality_engine_info_array from stage_six
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
                cast(stage as int) desc,
                date(evidence_date) desc
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
    evidence_date,
    evidence_desc,
    latest_rank_overall,
    quality_engine_info_array
from ranked
    )
;


  