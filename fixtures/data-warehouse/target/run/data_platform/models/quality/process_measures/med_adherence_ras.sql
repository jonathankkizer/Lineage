
  
    

create or replace transient table dw_dev.dev_jkizer_quality.med_adherence_ras
    copy grants
    
    
    as (with base_table as (
  select
    pat.suvida_id, 
    pat.quality_measure,
	  concat(
      'Next Refill Due: ', coalesce(pat.next_refill_due::string, 'N/A'),
      '. Perc Days Covered: ', coalesce(pat.perc_days_covered::string, 'N/A'),
      '. Real Time GDR: ', coalesce(pat.real_time_gdr::string, 'N/A'),
      '. Stage: ', coalesce(stage_med_adh_outreach, 'N/A')
    ) as evidence_desc,
    year(pat.measure_year) as measure_year,
    date(air.last_modified_datetime) as evidence_date,
    case 
        when pat.perc_days_covered >= 80 and year(pat.next_refill_due) = year('2025-12-31'::date) + 1 and pat.real_time_gdr >= 0 then 'Closed'
        when pat.perc_days_covered > 90 and year(pat.next_refill_due) = year('2025-12-31'::date) and pat.real_time_gdr >= 0 then 'Pending'
        when pat.perc_days_covered between 80 and 90 and year(pat.next_refill_due) = year('2025-12-31'::date) and pat.real_time_gdr >= 0 then 'Pending'
        when pat.perc_days_covered < 80 and year(pat.next_refill_due) = year('2025-12-31'::date) and pat.real_time_gdr >= 0 then 'Open'
        when pat.perc_days_covered < 80 and pat.real_time_gdr < 0 then 'Open'
    end as gap_status,
    case 
        when pat.perc_days_covered >= 80 and year(pat.next_refill_due) = year('2025-12-31'::date) + 1 and pat.real_time_gdr >= 0 then 'Permanently Passed'
        when pat.perc_days_covered > 90 and year(pat.next_refill_due) = year('2025-12-31'::date) and pat.real_time_gdr >= 0 then 'Currently Passing'
        when pat.perc_days_covered between 80 and 90 and year(pat.next_refill_due) = year('2025-12-31'::date) and pat.real_time_gdr >= 0 then 'At-Risk'
        when pat.perc_days_covered < 80 and year(pat.next_refill_due) = year('2025-12-31'::date) and pat.real_time_gdr >= 0 then 'Currently Failing'
        when pat.perc_days_covered < 80 and pat.real_time_gdr < 0 then 'Permanently Failed'
    end as med_adherence_gap_status,
    case 
        when pat.perc_days_covered < 80 and pat.real_time_gdr < 0 then 'No action needed (Failed)'
        when pat.perc_days_covered >= 80 and year(pat.next_refill_due) = year('2025-12-31'::date) + 1 and pat.real_time_gdr >= 0 then 'No action needed (Passed!)'
        when stage_med_adh_outreach is NULL then 'MedSpec not monitoring' 
        when stage_med_adh_outreach = 'Stage 1 - Patient Outreach: Attempting to reach the patient to discuss med adh' then 'Outreach in progress'
        when stage_med_adh_outreach = 'Stage 2 - Pending PCP Action (not eligible for SO)' then 'Assistance requested'
        when stage_med_adh_outreach = 'Stage 2 - Provider/Center Assistance Requested' then 'Assistance requested'
        when stage_med_adh_outreach = 'Stage 3 - Pending pick up/delivery; Rx Refilled' then 'Refilled, pending pickup'
        when stage_med_adh_outreach = 'Stage 4 - Requires outreach by center staff' then 'Assistance requested'
        when stage_med_adh_outreach = 'Stage 4 - Payor Data Refilled' then 'Picked up'
        when stage_med_adh_outreach = 'Stage 5 - Payor Data Refilled' then 'Picked up'
        when stage_med_adh_outreach = 'Stage 5 - Pick Up/Delivery Confirmed' then 'Picked up'
        when stage_med_adh_outreach = 'Stage 6 - Pick Up/Delivery Confirmed.' then 'Picked up'
        when stage_med_adh_outreach = 'Rx was discontinued - No outreach needed' then 'No action needed (Discontinued)'
        when stage_med_adh_outreach = '#NotbilledPartD' then 'No action needed (Not billed thru insurance)'
        when stage_med_adh_outreach = '#excludedfrommeasure' then 'No action needed (Excluded)'
        when stage_med_adh_outreach = '#InactivePatient' then 'No action needed (Inactive patient)'
        when stage_med_adh_outreach = '#deceased - care team was notified' then 'No action needed (Deceased)'
    end as stage_name,
    case 
        when pat.perc_days_covered < 80 and pat.real_time_gdr < 0 then 'Not Currently Monitoring'
        when pat.perc_days_covered >= 80 and year(pat.next_refill_due) = year('2025-12-31'::date) + 1 and pat.real_time_gdr >= 0 then 'Not Currently Monitoring'
        when stage_med_adh_outreach is NULL then 'Not Currently Monitoring' 
        when stage_med_adh_outreach = 'Stage 1 - Patient Outreach: Attempting to reach the patient to discuss med adh' then 'Outreach in progress'
        when stage_med_adh_outreach = 'Stage 2 - Pending PCP Action (not eligible for SO)' then 'Assistance requested'
        when stage_med_adh_outreach = 'Stage 2 - Provider/Center Assistance Requested' then 'Assistance requested'
        when stage_med_adh_outreach = 'Stage 3 - Pending pick up/delivery; Rx Refilled' then 'Refilled, pending pickup'
        when stage_med_adh_outreach = 'Stage 4 - Requires outreach by center staff' then 'Assistance requested'
        when stage_med_adh_outreach = 'Stage 4 - Payor Data Refilled' then 'Picked up'
        when stage_med_adh_outreach = 'Stage 5 - Payor Data Refilled' then 'Picked up'
        when stage_med_adh_outreach = 'Stage 5 - Pick Up/Delivery Confirmed' then 'Picked up'
        when stage_med_adh_outreach = 'Stage 6 - Pick Up/Delivery Confirmed.' then 'Picked up'
        when stage_med_adh_outreach = 'Rx was discontinued - No outreach needed' then 'Not Currently Monitoring'
        when stage_med_adh_outreach = '#NotbilledPartD' then 'Not Currently Monitoring'
        when stage_med_adh_outreach = '#excludedfrommeasure' then 'Not Currently Monitoring'
        when stage_med_adh_outreach = '#InactivePatient' then 'Not Currently Monitoring'
        when stage_med_adh_outreach = '#deceased - care team was notified' then 'Not Currently Monitoring'
    end as progress_bar,
    object_construct(
            'id', pat.med_adherence_measure_skey,
            'elation_object', '',
            'evidence_date', to_varchar(air.last_modified_datetime, 'MM/DD/YYYY'),
            'next_refill_due_date', coalesce(pat.next_refill_due::string, null), 
            'perc_days_covered', coalesce(pat.perc_days_covered::string, null),
            'real_time_gdr', coalesce(pat.real_time_gdr::string, null),
            'med_adherence_stage', coalesce(stage_med_adh_outreach, null),
            'rx_name', coalesce(pat.rx_name, null)
    ) as quality_engine_info_array
    from dw_dev.dev_jkizer.fct_med_adherence pat
    left join dw_dev.dev_jkizer.workflow_quality_med_adherence air on air.med_adherence_measure_skey = pat.med_adherence_measure_skey
        and air.is_automated_activity = false
    where pat.quality_measure = 'Med Adherence - RAS'
        and year(pat.measure_year) = year('2025-12-31'::date)
        and pat.measure_year_report_rank = 1
        and pat.patient_measure_report_rank = 1
        and pat.is_suspected_claim_reversal = FALSE
)
, ranked as (
    select *,
        row_number() over (
            partition by suvida_id, measure_year
            order by evidence_date desc
        ) as latest_rank_overall
    from base_table
)
select
    suvida_id,
    measure_year,
    quality_measure,
    null as stage,
    stage_name,
    gap_status,
    med_adherence_gap_status,
    progress_bar,
    evidence_date,
    evidence_desc,
    latest_rank_overall,
    object_insert(        
        quality_engine_info_array,
        'med_adherence_gap_status',
        med_adherence_gap_status
    ) as quality_engine_info_array
from ranked
    )
;


  