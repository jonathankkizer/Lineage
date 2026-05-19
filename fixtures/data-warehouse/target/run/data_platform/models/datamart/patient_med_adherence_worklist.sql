
  
    

create or replace transient table dw_dev.dev_jkizer.patient_med_adherence_worklist
    copy grants
    
    
    as (/* DEPRECATED */
select
	pme.suvida_id,
	pme.member_id,
	pme.measure_year,
	pme.measure_source,
	pme.quality_measure,
	pme.quality_measure_type,
	pme.measure_weight,
	pme.lis_level,
	pme.is_single_fill,
	pme.rx_name,
	pme.rx_number,
	pme.perc_days_covered,
	pme.measure_status,
	pme.measure_compliance_desc,
	pme.measure_numerator,
	pme.measure_denominator,
	pme.extended_day_opportunity,
	pme.gap_days_remaining,
	pme.member_status,
	pme.prescriber_name,
	pme.last_fill_date,
	pme.last_fill_day_supply,
	pme.next_refill_due,
	pme.refills_remaining,
	pme.rx_tier,
	pme.first_fill_date,
	pme.number_of_fills,
	pme.pharmacy_name,
	pme.pharmacy_phone,
	pme.pharmacy_address,
	null as adherence_risk_category,
	pme.report_date,
	pme.src_file_name,
from dw_dev.dev_jkizer.patient_med_adherence pme
where is_measure_year_current_report = true
    )
;


  