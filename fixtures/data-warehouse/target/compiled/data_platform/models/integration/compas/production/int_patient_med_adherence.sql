select distinct
    pma.med_adherence_measure_report_skey,
    pma.med_adherence_measure_skey,
    pma.suvida_id,
    pma.report_date,
    pma.quality_measure,
    pma.measure_year,
    pma.is_single_fill,
    pma.rx_name,
    pma.perc_days_covered,
    pma.prior_year_perc_days_covered,
    pma.gap_days_remaining,
    pma.prescriber_name as prescriber_name,
    pma.prescriber_user_id,
    pma.prescriber_phone,
    pma.last_fill_date,
    pma.last_fill_day_supply,
    pma.next_refill_due,
    pma.refills_remaining,
    pma.first_fill_date,
    pma.number_of_fills,
    pma.pharmacy_name,
    pma.pharmacy_phone,
    pma.pharmacy_address,
    pma.measure_source,
    pma.measure_weight,
    pma.quality_measure_type,
    pma.measure_status,
    pma.prior_year_measure_status,
    pma.patient_measure_report_rank,
    null as report_rank,
    pma.measure_year_report_rank,
    pma.is_measure_year_current_report,
    null as is_current_report,
    pma.is_first_measure_appearance,
    pma.workflow_airtable_id,
    pma.workflow_ms_notes as workflow_note,
    pma.current_quality_engine_status,
    pma.current_quality_engine_stage,
    pma.current_quality_engine_stage_name,
    pma.current_quality_engine_quality_engine_info_array as current_quality_engine_evidence,
    pma.is_suspected_claim_reversal,
    case
        when pma.current_quality_engine_status is not null then null
        when measure_status = 'closed' then 'Closed'
        when measure_status = 'open' then 'Open'
        else null
    end as quality_engine_status,
    case
        when pma.current_quality_engine_stage is not null then null
        when measure_status = 'closed' then 'Payer Closed'
        when measure_status = 'open' then null
        else null
    end as quality_engine_stage,
    ips.elation_id,
    pma.current_quality_engine_progress_bar
from dw_dev.dev_jkizer.patient_med_adherence pma
left join dw_dev.dev_jkizer.int_patient_summary ips
    on pma.suvida_id = ips.suvida_id
where
    ips.suvida_id is not null and
    year(pma.measure_year) >= year(current_date) - 1 and
    quality_measure not in (
        'Statin Therapy for Cardiovascular Disease',
        'Statin Use in Persons with Diabetes'
    )