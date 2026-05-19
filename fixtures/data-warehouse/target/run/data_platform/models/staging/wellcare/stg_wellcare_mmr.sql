
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellcare_mmr
  
  copy grants
  
  
  as (
    with stg_mmr as (
	select
		PLAN_NUMBER as plan_number,
		date(
			concat(
				substr(RUN_DATE, 3, 3), ' ', -- month
				left(left(RUN_DATE, 9), 2), -- day
				right(left(RUN_DATE, 9), 4) -- year
			)
		, 'MON DDYYYY') as run_date, -- e.g., Dec 30, 2006 then convert
		date(concat(PAYMENT_DATE,'01'), 'YYYYMMDD') as payment_date,
		CLAIM_NUMBER as medicare_beneficiary_id,
		SURNAME as surname,
		FIRST_INITIAL as first_initial,
		date(DATE_OF_BIRTH, 'YYYYMMDD') as birth_date,
		SEX as gender_code,
		AGE_GROUP as age_group,
		RACE_CODE as race_code,
		STATE_COUNTY_CODE as state_county_code,
		OUT_OF_AREA as ooa_ind,
		date(PAYMENT_ADJUSTMENT_START_DATE, 'YYYYMMDD') as adjustment_start_date,
		date(PAYMENT_ADJUSTMENT_END_DATE, 'YYYYMMDD') as adjustment_end_date,
		num_of_paymt_adj_months_part_a as num_months_part_a,
		num_of_paymt_adj_months_part_b as num_months_part_b,
		PART_A_ENTITLEMENT as part_a_entitlement,
		PART_B_ENTITLEMENT as part_b_entitlement,
		RISK_ADJUSTOR_FACTOR_A as risk_adjustor_factor_a,
		RISK_ADJUSTOR_FACTOR_B as risk_adjustor_factor_b,
		HOSPICE as hospice_ind,
		ESRD as esrd_ind,
		WORKING_AGED as working_aged_ind,
		INSTITUTIONAL as institutional,
		FRAILTY_IND as frailty_ind,
		NURSING_HOME_CERTIFIABLE as nhc_ind,
		MEDICAID as medicaid_status_ind,
		MEDICAID_ADD_ON as medicaid_add_on_ind,
		RA_FACTOR_TYPE_CODE as raf_type_code,
		MEDICAID_DUAL_STATUS_CODE as medicaid_dual_status_code,
		iff(medicaid_dual_status_code > 0, true, false) as dual_status_bool,
		CURRENT_MEDICAID_FLAG as current_medicaid_ind,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
		iff(src_file_name like '%xlsx%', 
			date(replace(right(src_file_name, 13), '.xlsx', ''), 'YYYYMMDD'),
			date(replace(right(src_file_name, 12), '.txt', ''), 'YYYYMMDD')
		) as src_file_date,
		TOTAL_MA_PAYMENT_AMT,
		PARTD_SUP_BEN_PARTA_REBATE_AMT as partd_sup_ben_parta_rebate_amt,
		PARTD_SUP_BEN_PARTB_REBATE_AMT as partd_sup_ben_partb_rebate_amt,
		ADJUSTMENT_REASON_CODE as adjustment_reason_code,
		partd_basic_prem_amt as part_d_basic_premium,
		partd_dir_subsidy_payment_amt as part_d_direct_subsidy_amount,
		'Wellcare/Centene' as source
	from airbyte_source_prod.wellcare_tx.mmr
)
select
	*,
	iff(esrd_ind = 'Y', 2, 0) as original_reason_entitlement_code,
	dense_rank() over (partition by medicare_beneficiary_id, adjustment_start_date order by src_file_date desc) as mmr_process_month_report_rank,
from stg_mmr
  );

