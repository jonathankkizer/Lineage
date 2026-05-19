
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_tx_claim
  
  copy grants
  
  
  as (
    with claims as (
	select
		nullif(member_alt_id::varchar, '') as member_id,
		nullif(audit_no::varchar, '') as claim_id,
		try_cast(nullif(audit_sub::varchar, '') as integer) as audit_sub,
		nullif(authorization_number::varchar, '') as AUTHORIZATION_NUMBER,
		date(nullif(begin_dos::varchar, ''), 'DDMonYYYY') as BEGIN_DOS,
		date(nullif(end_dos::varchar, ''), 'DDMonYYYY') as END_DOS,
		nullif(bill_type_code::varchar, '') as BILL_TYPE_CODE,
		nullif(cap_flag::varchar, '') as CAP_FLAG,
		nullif(cc_code::varchar, '') as CC_CODE,
		nullif(claimed_amount::varchar, '') as CLAIMED_AMOUNT,
		nullif(claim_location_code::varchar, '') as CLAIM_LOCATION_CODE,
		nullif(clinic_name::varchar, '') as CLINIC_NAME,
		nullif(clmo::varchar, '') as CLMO,
		nullif(contract_nbr::varchar, '') as CONTRACT_NBR,
		nullif(cpt_revenue_code::varchar, '') as CPT_REVENUE_CODE,
		nullif(cy_py::varchar, '') as CY_PY,
		nullif(denial_reason_code::varchar, '') as DENIAL_REASON_CODE,
		nullif(description_of_service::varchar, '') as DESCRIPTION_OF_SERVICE,
		try_cast(nullif(detail_line_no::varchar, '') as integer) as claim_line_number,
		trim(nullif(primary_diagnosis_code::varchar, '')) as icd_10_code_1,
		trim(nullif(diagnosis_code_2::varchar, '')) as icd_10_code_2,
		trim(nullif(diagnosis_code_3::varchar, '')) as icd_10_code_3,
		trim(nullif(diagnosis_code_4::varchar, '')) as icd_10_code_4,
		trim(nullif(diagnosis_code_5::varchar, '')) as icd_10_code_5,
		trim(nullif(diagnosis_code_6::varchar, '')) as icd_10_code_6,
		trim(nullif(diagnosis_code_7::varchar, '')) as icd_10_code_7,
		trim(nullif(diagnosis_code_8::varchar, '')) as icd_10_code_8,
		trim(nullif(diagnosis_code_9::varchar, '')) as icd_10_code_9,
		trim(nullif(diagnosis_code_10::varchar, '')) as icd_10_code_10,
		trim(nullif(diagnosis_code_11::varchar, '')) as icd_10_code_11,
		trim(nullif(diagnosis_code_12::varchar, '')) as icd_10_code_12,
		trim(nullif(diagnosis_code_13::varchar, '')) as icd_10_code_13,
		trim(nullif(diagnosis_code_14::varchar, '')) as icd_10_code_14,
		trim(nullif(diagnosis_code_15::varchar, '')) as icd_10_code_15,
		trim(nullif(diagnosis_code_16::varchar, '')) as icd_10_code_16,
		trim(nullif(diagnosis_code_17::varchar, '')) as icd_10_code_17,
		trim(nullif(diagnosis_code_18::varchar, '')) as icd_10_code_18,
		trim(nullif(diagnosis_code_19::varchar, '')) as icd_10_code_19,
		trim(nullif(diagnosis_code_20::varchar, '')) as icd_10_code_20,
		trim(nullif(diagnosis_code_21::varchar, '')) as icd_10_code_21,
		trim(nullif(diagnosis_code_22::varchar, '')) as icd_10_code_22,
		trim(nullif(diagnosis_code_23::varchar, '')) as icd_10_code_23,
		trim(nullif(diagnosis_code_24::varchar, '')) as icd_10_code_24,
		trim(nullif(diagnosis_code_25::varchar, '')) as icd_10_code_25,
		nullif(discharge_status::varchar, '') as DISCHARGE_STATUS,
		nullif(drg::varchar, '') as DRG,
		nullif(gender::varchar, '') as GENDER,
		nullif(mbi::varchar, '') as MBI,
		nullif(member_age::varchar, '') as MEMBER_AGE,
		nullif(member_alt_id::varchar, '') as MEMBER_ALT_ID,
		nullif(member_first_name::varchar, '') as MEMBER_FIRST_NAME,
		nullif(member_last_name::varchar, '') as MEMBER_LAST_NAME,
		nullif(date_of_birth::varchar, '') as DATE_OF_BIRTH,
		nullif(member_group::varchar, '') as MEMBER_GROUP,
		nullif(network_name::varchar, '') as NETWORK_NAME,
		nullif(number_of_units::varchar, '') as NUMBER_OF_UNITS,
		nullif(paid_amount::varchar, '') as PAID_AMOUNT,
		date(nullif(paid_date::varchar, ''), 'DDMonYYYY') as PAID_DATE,
		nullif(pcp_name::varchar, '') as PCP_NAME,
		nullif(pcp_no::varchar, '') as PCP_NO,
		nullif(pcp_npi::varchar, '') as PCP_NPI,
		nullif(provider_name::varchar, '') as PROVIDER_NAME,
		nullif(srvc_provider_npi_number::varchar, '') as SRVC_PROVIDER_NPI_NUMBER,
		nullif(site_code::varchar, '') as place_of_service_code,
		nullif(segment_nbr::varchar, '') as SEGMENT_NBR,
		nullif(referral_prov_no_facility_code::varchar, '') as REFERRAL_PROV_NO_FACILITY_CODE,
		nullif(record_id::varchar, '') as RECORD_ID,
		nullif(received_date::varchar, '') as RECEIVED_DATE,
		nullif(provider_no::varchar, '') as PROVIDER_NO,
		nullif(proc_1_cd::varchar, '') as PROC_1_CD,
		nullif(proc_2_cd::varchar, '') as PROC_2_CD,
		nullif(proc_3_cd::varchar, '') as PROC_3_CD,
		nullif(proc_4_cd::varchar, '') as PROC_4_CD,
		nullif(proc_5_cd::varchar, '') as PROC_5_CD,
		nullif(nullif(procedure_code::varchar, ''), 'N/A') as PROCEDURE_CODE,
		nullif(procedure_mod_code_1::varchar, '') as PROCEDURE_MOD_CODE_1,
		nullif(procedure_mod_code_2::varchar, '') as PROCEDURE_MOD_CODE_2,
		nullif(procedure_mod_code_3::varchar, '') as PROCEDURE_MOD_CODE_3,
		nullif(procedure_mod_code_4::varchar, '') as PROCEDURE_MOD_CODE_4,
		nullif(procedure_mod_description_1::varchar, '') as PROCEDURE_MOD_DESCRIPTION_1,
		nullif(procedure_mod_description_2::varchar, '') as PROCEDURE_MOD_DESCRIPTION_2,
		nullif(procedure_mod_description_3::varchar, '') as PROCEDURE_MOD_DESCRIPTION_3,
		nullif(procedure_mod_description_4::varchar, '') as PROCEDURE_MOD_DESCRIPTION_4,
		nullif(pos_desc::varchar, '') as POS_DESC,
		nullif(pcr_amount::varchar, '') as PCR_AMOUNT,
		nullif(pool::varchar, '') as POOL,
		nullif(pbp::varchar, '') as PBP,
		nullif(par_status::varchar, '') as PAR_STATUS,
		src_file_name,
		iff(
		  nullif(clinic_name::varchar, '') = 'SUVIDA HEALTHCARE'
		  or nullif(provider_name::varchar, '') in ('NAVA, ANDREW', 'SUVIDA HEALTHCARE CLINICA', 'CORDOVA, FRANCISCO', 'JIMENEZ, RODOLFO', 'DE LA TORRE, LAURA E', 'JIMENEZ, LOHENGRIN', 'GOMEZ, FRANCISCO E', 'SUVIDA HEALTHCARE CLINICAL', 'GIL, ANDRES F', 'FUENTEVILLA, ANA', 'NAVA, M.D., ANDREW', 'SUVIDA HEALTHCARE CLINICAL SERVICES LLC', 'CORDOVA, M.D., FRANCISCO', 'SUVIDA HEALTHCARE LLC', 'ORDONEZ, M.D., ADOLFO JOSE', 'JIMENEZ, D.O., RODOLFO', 'DE LA TORRE, M.D., LAURA ELIAS', 'JIMENEZ, N.P., LOHENGRIN', 'FUENTEVILLA, M.D., ANA', 'GIL, F.N.P., ANDRES FERNANDO', 'DE LA TORRE, LAURA E.', 'GOMEZ, FRANCISCO E.', 'GIL, ANDRES F.', 'KISELYK, ANGELA C.'),
		  '882864363',
		  null
		) as rendering_tin

	from airbyte_source_prod.united_tx.claims_medical
), uhc_tx_claims_data as (
	select
		*,
		date(
			concat(
				regexp_substr(src_file_name, '\\d{4}'),
				regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)', 1, 1, 'i'),
				'01'
			),
			'YYYYMonDD'
		) as report_date
	from claims
)
select
	case
		when len(member_id) = 11 then right(replace(member_id, '-1', ''), 7)::varchar || '01'
		else member_id
	end as member_id,
	* exclude (member_id, claim_line_number),
	iff(lower(pool) in ('physician'), 'professional', 'institutional') as claim_type,
	'United TX' as source,
	claim_line_number + row_number() over (partition by claim_id order by claim_line_number asc) as claim_line_number,
	dense_rank() over (partition by year(begin_dos) order by report_date desc) as claims_report_rank,
	min(report_date) over (partition by claim_id, claim_line_number) as first_received_date,
from uhc_tx_claims_data
where src_file_name != ''
and claim_line_number is not null
  );

