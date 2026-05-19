
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_quality_measure_sandbox
    copy grants
    
    
    as (select
    pqm.quality_measure_skey,
    pqm.quality_measure_report_skey,
    ipss.suvida_id,
    pqm.report_date,
    pqm.quality_measure,
    pqm.measure_year,
    pqm.measure_source,
    pqm.measure_weight,
    pqm.quality_measure_type,
    null as measure_detail,
    pqm.measure_status,
    pqm.prior_year_measure_status,
    pqm.suvida_measure_status,
    pqm.suvida_measure_date,
    null as evidence_desc,
    pqm.combined_measure_status,
    pqm.patient_measure_report_rank,
    pqm.patient_report_rank,
    null as report_rank,
    pqm.measure_year_report_rank,
    pqm.is_measure_year_current_report,
    null as is_current_report,
    pqm.is_first_measure_appearance,
    null as workflow_airtable_id,
    pqm.workflow_status,
    pqm.workflow_status_detail,
    null as workflow_note,
    pqm.workflow_last_modified_by_name,
    pqm.workflow_last_modified_by_email,
    pqm.workflow_last_modified_by_datetime,
    pqm.current_quality_engine_status,
    pqm.current_quality_engine_stage,
    pqm.current_quality_engine_stage_name,
    case
        when pqm.current_quality_engine_status is not null then null
        when measure_status = 'closed' and suvida_measure_status is null then 'Closed'
        when measure_status = 'closed' and suvida_measure_status = 'closed' then 'Closed'
        when measure_status = 'closed' and suvida_measure_status = 'open' then 'Closed'
        when measure_status = 'closed' and suvida_measure_status = 'pending' then 'Closed'
        when measure_status = 'open' and suvida_measure_status is null then 'Open'
        when measure_status = 'open' and suvida_measure_status = 'open' then
            case
                when workflow_status = 'Pending Closure' and workflow_status_detail = 'Submitted - Pending Payer Audit' then 'Pending'
                else 'Open'
            end
        when measure_status = 'open' and suvida_measure_status = 'closed' then 'Pending'
        when measure_status = 'open' and suvida_measure_status = 'pending' then 'Pending'
        else null
    end as quality_engine_status,
    case
        when pqm.current_quality_engine_stage is not null then null
        when measure_status = 'closed' and suvida_measure_status is null then 'Payer Closed'
        when measure_status = 'closed' and suvida_measure_status = 'closed' then 'Payer Closed'
        when measure_status = 'closed' and suvida_measure_status = 'open' then 'Payer Closed'
        when measure_status = 'closed' and suvida_measure_status = 'pending' then 'Payer Closed'
        when measure_status = 'open' and suvida_measure_status is null then null
        when measure_status = 'open' and suvida_measure_status = 'open' then
            case
                when workflow_status = 'Pending Closure' and workflow_status_detail = 'Submitted - Pending Payer Audit' then 'Supplemental Data Submitted'
                else null
            end
        when measure_status = 'open' and suvida_measure_status = 'closed' then
            case
                when workflow_status = 'Pending Closure' and workflow_status_detail = 'Submitted - Pending Payer Audit' then 'Supplemental Data Submitted'
                else null
            end
        when measure_status = 'open' and suvida_measure_status = 'pending' then 'Pending'
        else null
    end as quality_engine_stage,
    quality_engine.evidence_desc as current_quality_engine_evidence_desc,
    quality_engine.evidence_date as current_quality_engine_evidence_date,
    quality_engine.quality_engine_info_array as current_quality_engine_evidence,
    ipss.elation_id,
    case
        when pqm.quality_measure like 'TRC - %' then TRUE
        when pqm.quality_measure like 'Transitions of Care%' then TRUE
        when pqm.quality_measure = 'Plan All-Cause Readmissions' then TRUE
        when pqm.quality_measure = 'Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)' then TRUE
        else FALSE
    end as is_trc_measure,
    pqm.compas_flag
from dw_dev.dev_jkizer.patient_quality_measure pqm
left join dw_dev.dev_jkizer_quality.quality_process_measures quality_engine 
	on pqm.quality_measure = quality_engine.quality_measure
	and pqm.suvida_id = quality_engine.suvida_id
	and year(pqm.measure_year) = quality_engine.measure_year
	and quality_engine.latest_rank_overall  = 1
left join dw_dev.dev_jkizer.int_patient_summary_sandbox ipss
    on md5(cast(coalesce(cast(pqm.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) = ipss.suvida_id
where
    ipss.suvida_id is not null and
    pqm.quality_measure not in (
        'Med Adherence - Diabetes',
        'Med Adherence - RAS',
        'Med Adherence - Statins'
    ) and
    year(pqm.measure_year) >= year(current_date) - 1
    )
;


  