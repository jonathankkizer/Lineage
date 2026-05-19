
  
    

create or replace transient table dw_dev.dev_jkizer.patient_med_adherence
    copy grants
    
    
    as (with recent_mah_note as (
    select
        encounter_skey,
        suvida_id,
        note_text,
        encounter_date,
        'Med Adherence - Statins' as quality_measure,
    from dw_dev.dev_jkizer.fct_encounter fe
    where encounter_type = 'med_adherence_note'
    and (fe.note_text ilike '%measure% mah%' or fe.note_text ilike '%measure%#mah%')
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
), recent_mad_note as (
    select
        encounter_skey,
        suvida_id,
        note_text,
        encounter_date,
        'Med Adherence - Diabetes' as quality_measure,
    from dw_dev.dev_jkizer.fct_encounter fe
    where encounter_type = 'med_adherence_note'
    and (fe.note_text ilike '%measure% mad%' or fe.note_text ilike '%measure%#mad%')
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
), recent_mac_note as (
    select
        encounter_skey,
        suvida_id,
        note_text,
        encounter_date,
        'Med Adherence - RAS' as quality_measure,
    from dw_dev.dev_jkizer.fct_encounter fe
    where encounter_type = 'med_adherence_note'
    and (fe.note_text ilike '%measure% mac%' or fe.note_text ilike '%measure%#mac%')
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
), prior_year as (
    select
		suvida_id,
		quality_measure,
		measure_status,
		perc_days_covered,
		measure_year,
	from dw_dev.dev_jkizer.fct_med_adherence
	where measure_year_report_rank = 1
	and measure_year = dateadd(year, -1, date_trunc(year, current_date()))
    qualify row_number() over (partition by suvida_id, quality_measure order by report_date desc) = 1
)
select
    med_adh.med_adherence_measure_report_skey,
    med_adh.med_adherence_measure_skey,
    med_adh.suvida_id,
    med_adh.member_id,
    med_adh.measure_source,
    med_adh.quality_measure,
    med_adh.quality_measure_type,
    med_adh.measure_weight,
    med_adh.lis_level,
    med_adh.measure_year,
    med_adh.is_single_fill,
    med_adh.rx_name,
    med_adh.rx_number,
    med_adh.perc_days_covered,
    med_adh.measure_status,
    py.measure_status as prior_year_measure_status,
    py.perc_days_covered as prior_year_perc_days_covered,
    med_adh.measure_status_v2,
    med_adh.measure_compliance_desc,
    med_adh.measure_numerator,
    med_adh.measure_numerator_v2,
    med_adh.measure_denominator,
    med_adh.ninety_day_opportunity as extended_day_opportunity,
    med_adh.gap_days_remaining,
    med_adh.member_status,
    coalesce(pum.user_name, med_adh.prescriber_name) as prescriber_name,
    pum.user_id as prescriber_user_id,
    med_adh.prescriber_phone,
    med_adh.last_fill_date,
    med_adh.last_fill_day_supply,
    med_adh.next_refill_due,
    med_adh.refills_remaining,
    med_adh.rx_tier,
    med_adh.first_fill_date,
    med_adh.number_of_fills,
    med_adh.pharmacy_name,
    med_adh.pharmacy_phone,
    med_adh.pharmacy_address,
    med_adh.measure_program,
    med_adh.payer_group,
    med_adh.report_date,
    med_adh.src_file_name,
    med_adh.report_type,
    med_adh.med_adherence_report_rank,
    med_adh.patient_measure_report_rank,
    med_adh.patient_report_rank,
    -- med_adh.report_rank,
    med_adh.measure_year_report_rank,
    -- med_adh.med_adherence_measure_rn,
    quality_engine.gap_status as current_quality_engine_status,
	quality_engine.stage_name as current_quality_engine_stage_name,
	quality_engine.stage as current_quality_engine_stage,
    quality_engine.med_adherence_gap_status as current_quality_engine_med_adherence_gap_status,
    case 
		when lower(quality_engine.gap_status) in ('pending', 'closed') or med_adh.measure_numerator = 1 
		then 1 
		else 0 
	end as quality_engine_measure_numerator,
	quality_engine.quality_engine_info_array as current_quality_engine_quality_engine_info_array,
    quality_engine.progress_bar as current_quality_engine_progress_bar,
    iff(med_adh.measure_year_report_rank = 1, true, false) as is_measure_year_current_report,
    -- iff(med_adh.report_rank = 1 and med_adh.patient_report_rank = 1 and year(med_adh.measure_year) = year(current_date()), true, false) as is_current_report,
    iff(med_adh.med_adherence_measure_rn = 1, true, false) as is_first_measure_appearance,
    med_adh.is_suspected_claim_reversal,
    med_adh.absolute_fail_date,
    coalesce(rmn.note_text, rmdn.note_text, rmcn.note_text) as recent_med_adherence_note_text,
    wqm.airtable_id as workflow_airtable_id,
    wqm.ms_notes as workflow_ms_notes,
from dw_dev.dev_jkizer.fct_med_adherence med_adh
left join recent_mah_note rmn
    on med_adh.suvida_id = rmn.suvida_id
    and med_adh.quality_measure = rmn.quality_measure
left join recent_mad_note rmdn
    on med_adh.suvida_id = rmdn.suvida_id
    and med_adh.quality_measure = rmdn.quality_measure
left join recent_mac_note rmcn
    on med_adh.suvida_id = rmcn.suvida_id
    and med_adh.quality_measure = rmcn.quality_measure
left join prior_year py
	on med_adh.suvida_id = py.suvida_id
	and med_adh.quality_measure = py.quality_measure
	and med_adh.measure_year = dateadd(year, 1, py.measure_year)
left join dw_dev.dev_jkizer.workflow_quality_med_adherence wqm
    on med_adh.med_adherence_measure_skey = wqm.med_adherence_measure_skey
    and wqm.workflow_status_index = 1
left join dw_dev.dev_jkizer_quality.quality_process_measures quality_engine
	on med_adh.quality_measure = quality_engine.quality_measure
	and med_adh.suvida_id = quality_engine.suvida_id
	and year(med_adh.measure_year) = quality_engine.measure_year
	and quality_engine.latest_rank_overall  = 1
left join dw_dev.dev_jkizer.dim_prescriber_user_mapping pum
    on med_adh.prescriber_name = pum.prescriber_name
    and med_adh.measure_year = date_trunc(year, current_date())
where year(med_adh.measure_year) in (year(current_date()), year(current_date()) - 1) -- filter to current and prior measure year
and med_adh.suvida_id is not null
and med_adherence_report_in_month_rank = 1 -- grabbing latest data available for each month
    )
;


  