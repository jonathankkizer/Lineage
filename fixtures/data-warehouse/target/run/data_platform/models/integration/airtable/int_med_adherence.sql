
  
    

create or replace transient table dw_dev.dev_jkizer.int_med_adherence
    copy grants
    
    
    as (-- Airtable base: Pharmacy Quality Operations

select
	med_adherence_measure_skey,
	pm.suvida_id,
	member_id,
	measure_source,
	quality_measure,
	quality_measure_type,
	measure_weight as measure_weight,
	lis_level as lis_level,
	measure_year,
	is_single_fill,
	rx_name,
	rx_number::varchar as rx_number,
	perc_days_covered as perc_days_covered,
	measure_status,
	prior_year_measure_status,
	measure_status_v2,
	measure_numerator,
	measure_numerator_v2,
	measure_denominator,
	extended_day_opportunity,
	gap_days_remaining,
	prescriber_name,
	prescriber_phone,
	last_fill_date,
	last_fill_day_supply,
	next_refill_due,
	round(refills_remaining, 0) as refills_remaining,
	rx_tier,
	first_fill_date,
	round(number_of_fills, 0) as number_of_fills,
	pharmacy_name,
	pharmacy_phone,
	pharmacy_address,
	measure_program,
	payer_group,
	report_date,
	src_file_name,
	ps.location_name,
	ps.provider_name,
	ps.provider_npi,
	ps.next_pcp_appt_date,
	ps.last_pcp_appt_date,
	ps.payer_parent,
	ps.payer_name,
	ps.payer_contract,
	ps.full_name,
	ps.birth_date,
	ps.elation_patient_url,
	/* current vital, lab info */
	pmc.most_recent_bp_date,
	pmc.most_recent_bp,
	pmc.most_recent_a1c_date,
	pmc.most_recent_a1c,
	pmc.most_recent_ldl_date,
	to_varchar(pmc.most_recent_ldl) as most_recent_ldl,
	pmc.most_recent_hdl_date,
	to_varchar(pmc.most_recent_hdl) as most_recent_hdl,
	pmc.most_recent_triglyceride_date,
	to_varchar(pmc.most_recent_triglyceride) as most_recent_triglyceride,
	pmc.most_recent_total_cholesterol_date,
	to_varchar(pmc.most_recent_total_cholesterol) as most_recent_total_cholesterol,
	pe.note_text as recent_med_adherence_note,
	date(pe.encounter_datetime) as recent_med_adherence_note_date,
	/* monthly quality measure statuses */
	pmq.hbd_status as "Quality - A1C",
	pmq.hbd_qe_stage as "Quality - A1C QE Stage",
	pmq.cbp_status as "Quality - CBP",
	pmq.cbp_qe_stage as "Quality - CBP QE Stage",
	pmq.supd_status as "Quality - SUPD",
	pmq.supd_qe_stage as "Quality - SUPD QE Stage",
	pmq.spc_status as "Quality - SPC",
	pmq.spc_qe_stage as "Quality - SPC QE Stage",
	pmq.mah_status as "Quality - MAH",
	pmq.mah_qe_stage as "Quality - MAH QE Stage",
	pmq.mad_status as "Quality - MAD",
	pmq.mad_qe_stage as "Quality - MAD QE Stage",
	pmq.mac_status as "Quality - MAC",
	pmq.mac_qe_stage as "Quality - MAC QE Stage",
	pmq.poly_ach_status as "Quality - PolyACH",
	null as "Quality - PolyACH QE Stage",
	pmq.cob_status as "Quality - COB",
	null as "Quality - COB QE Stage",
	pmq.bcs_status as "Quality - BCS",
	pmq.bcs_qe_stage as "Quality - BCS QE Stage",
	pmq.fsa_status as "Quality - FSA",
	pmq.fsa_qe_stage as "Quality - FSA QE Stage",
	pmq.coa_mdr_status as "Quality - COA",
	pmq.coa_mdr_qe_stage as "Quality - COA QE Stage",
	pmq.col_status as "Quality - COL",
	pmq.col_qe_stage as "Quality - COL QE Stage",
	pmq.eed_status as "Quality - EED",
	pmq.eed_qe_stage as "Quality - EED QE Stage",
	pmq.ked_status as "Quality - KED",
	pmq.ked_qe_stage as "Quality - KED QE Stage",
	pmq.fmc_status as "Quality - FMC",
	null as "Quality - FMC QE Stage",
	pmq.omw_status as "Quality - OMW",
	pmq.omw_qe_stage as "Quality - OMW QE Stage",
	pmq.pcpov_status as "Quality - PCPOV",
	pmq.pcpov_qe_stage as "Quality - PCPOV QE Stage",
	pmq.pcr_status as "Quality - PCR",
	null as "Quality - PCR QE Stage",
	pmq.poly_cns_status as "Quality - PolyCNS",
	null as "Quality - PolyCNS QE Stage",
	pmq.zephyr_status as "Quality - Zephyr",
	pmq.zephyr_qe_stage as "Quality - Zephyr QE Stage",
	pmq.mrp_status as "Quality - MRP",
	null as "Quality - MRP QE Stage",
	pmq.nia_status as "Quality - NIA",
	null as "Quality - NIA QE Stage",
	pmq.ped_status as "Quality - PED",
	null as "Quality - PED QE Stage",
	pmq.pe7_status as "Quality - PE7",
	null as "Quality - PE7 QE Stage",
	pmq.rdi_status as "Quality - RDI",
	null as "Quality - RDI QE Stage",
	md5(cast(coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pe.encounter_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_bp_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_a1c_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_ldl_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_hdl_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_triglyceride_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_total_cholesterol_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as med_adherence_measure_integration_skey,
from dw_dev.dev_jkizer.patient_med_adherence pm
left join dw_dev.dev_jkizer.patient_summary ps
	on pm.suvida_id = ps.suvida_id
left join dw_dev.dev_jkizer.patient_encounter pe
	on pm.suvida_id = pe.suvida_id
	and pe.encounter_type_idx = 1
	and pe.encounter_type = 'med_adherence_note'
left join dw_dev.dev_jkizer.patient_monthly_clinical_values pmc
	on pm.suvida_id = pmc.suvida_id
	and pmc.is_current_month = true
left join dw_dev.dev_jkizer.patient_monthly_quality pmq
	on pm.suvida_id = pmq.suvida_id
	and pmq.is_current_month = true
where measure_year = '2025-01-01' -- manually set measure year
and is_measure_year_current_report = true
qualify row_number() over (partition by med_adherence_measure_skey order by report_type asc) = 1
    )
;


  