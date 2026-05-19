
  
    

create or replace transient table dw_dev.dev_jkizer.int_quality_operations_long_2026
    copy grants
    
    
    as (-- Airtable base: Quality Operations (2026)

with immunizations as (
    select
        suvida_id,
        listagg(
            quality_measure || '|' || suvida_measure_status || '|' || evidence_date,
            ', '
        ) within group(order by quality_measure) as immunizations_status
    from dw_dev.dev_jkizer_quality.stars_suvida_logic
    where quality_measure in (
        'Suvida - Zoster',
        'Suvida - Flu Vaccine',
        'Suvida - Pneumococcal Vaccine',
        'Suvida - TDAP',
        'Suvida - covid'
    )
    group by suvida_id
)
select
	quality_measure_skey,
	full_name,
	birth_date,
	pqm.suvida_id,
	elation_patient_url,
	coalesce(payer_member_id, elation_insurance_member_id) as payer_member_id,
	location_name,
	provider_name,
	last_pcp_appt_date,
	next_pcp_appt_date,
	ps.next_ma_appt_date,
	ps.next_pharmacy_appt_date,
	ps.next_ma_appt_description,
	ps.payer_parent,
	ps.payer_name,
	ps.payer_contract,
	last_awv_date,
	measure_source,
	measure_year,
	quality_measure,
	quality_measure_type,
	measure_status,
	imm.immunizations_status,
	measure_detail,
	report_date,
	src_file_name,
	awell_started_date,
	awell_completed_date, 
	is_outreach_successful, 
	awell_appointment_date,
	awell_notes,
	suvida_measure_status,
	evidence_desc as suvida_evidence_desc,
	null as suvida_stage, -- placeholder for potential future logic
	aco_flag,
	payer_group,
	ps.high_risk_patient,
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
	pqm.current_quality_engine_status,
	pqm.current_quality_engine_stage_name,
	pqm.current_quality_engine_stage,
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
	md5(cast(coalesce(cast(quality_measure_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_ma_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pharmacy_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_ma_appt_description as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(awell_started_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(awell_completed_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_bp_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_a1c_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_ldl_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_hdl_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_triglyceride_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pmc.most_recent_total_cholesterol_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(imm.immunizations_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pqm.current_quality_engine_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pqm.current_quality_engine_stage_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pqm.current_quality_engine_stage as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as quality_measure_integration_skey,
from dw_dev.dev_jkizer.patient_quality_measure pqm
left join immunizations imm
    on imm.suvida_id = pqm.suvida_id
left join dw_dev.dev_jkizer.patient_summary ps
	on pqm.suvida_id = ps.suvida_id
left join dw_dev.dev_jkizer.patient_monthly_clinical_values pmc 
	on pqm.suvida_id = pmc.suvida_id
	and pmc.is_current_month = true
left join dw_dev.dev_jkizer.patient_monthly_quality pmq
	on pqm.suvida_id = pmq.suvida_id
	and pmq.is_current_month = true
where is_measure_year_current_report = true 
and measure_year = '2026-01-01' -- lock this manually -- so we update this to control which measure year flows to Airtable, and avoid it automatically flipping when the year changes
    )
;


  