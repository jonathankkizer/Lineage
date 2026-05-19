
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_az_mmr
  
  copy grants
  
  
  as (
    with united_mmr_data as (
	select
		to_varchar(member_alt_id) as member_id,
		date(payment_date, 'YYYYMM') as payment_month,
		date(apply_date, 'DDMonYYYY') as apply_month,
		gross_revenue,
		nullif(risk_adj_fctr_a, '0.000') as raf_score,
		adjustment_reason_code,
		default_risk_adj_flg,
		esrd_mbr_msp_flg,
		esrd_flg,
		iff(mcaid_status_flg = 1, true, false) as dual_status_bool,
		risk_adj_factor_typ_cd as raf_type_code,
		risk_adj_factor_typ_cd_desc,
		frailty_flg,
		orig_rsn_for_entitlement as original_reason_entitlement_code,
		concat(contract_nbr, '-', lpad(pbp, 3, '0'), '-', lpad(segment_nbr, 3, '0')) as pbp_code,
		src_file_name,
		'United' as source,
		date(concat(left(split_part(replace(src_file_name, '_RUNOUT', ''), '_', -1), 4), split_part(replace(src_file_name, '_RUNOUT', ''), '_', -2), '01'), 'YYYYMonDD') as src_file_date,
		0.85 as percent_of_payment,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Phoenix' as payer_contract,
	from SOURCE_PROD.united.src_united_mmr_hmo_phoenix
	
	union all
	
	select
		to_varchar(member_alt_id) as member_id,
		date(payment_date, 'YYYYMM') as payment_month,
		date(apply_date, 'DDMonYYYY') as apply_month,
		gross_revenue,
		nullif(risk_adjuster_factor_a, '0.000') as raf_score,
		adjustment_reason_code,
		default_risk_adj_flg,
		esrd_mbr_msp_flg,
		esrd_flg,
		iff(mcaid_status_flg = 1, true, false) as dual_status_bool,
		risk_adj_factor_typ_cd as raf_type_code,
		risk_adj_factor_typ_cd_desc,
		frailty_flg,
		orig_rsn_for_entitlement as original_reason_entitlement_code,
		concat(contract_nbr, '-', lpad(pbp, 3, '0'), '-', lpad(segment_nbr, 3, '0')) as pbp_code,
		src_file_name,
		'United' as source,
		date(concat(left(split_part(replace(src_file_name, '_RUNOUT', ''), '_', -1), 4), split_part(replace(src_file_name, '_RUNOUT', ''), '_', -2), '01'), 'YYYYMonDD') as src_file_date,
		0.85 as percent_of_payment,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Phoenix' as payer_contract,
	from SOURCE_PROD.united.src_united_mmr_ppo_phoenix
	
	union all
	
	select
		to_varchar(member_alt_id) as member_id,
		date(payment_date, 'YYYYMM') as payment_month,
		date(apply_date, 'DDMonYYYY') as apply_month,
		gross_revenue,
		nullif(risk_adj_fctr_a, '0.000') as raf_score,
		adjustment_reason_code,
		default_risk_adj_flg,
		esrd_mbr_msp_flg,
		esrd_flg,
		iff(mcaid_status_flg = 1, true, false) as dual_status_bool,
		risk_adj_factor_typ_cd as raf_type_code,
		risk_adj_factor_typ_cd_desc,
		frailty_flg,
		orig_rsn_for_entitlement as original_reason_entitlement_code,
		concat(contract_nbr, '-', lpad(pbp, 3, '0'), '-', lpad(segment_nbr, 3, '0')) as pbp_code,
		src_file_name,
		'United' as source,
		date(concat(left(split_part(replace(src_file_name, '_RUNOUT', ''), '_', -1), 4), split_part(replace(src_file_name, '_RUNOUT', ''), '_', -2), '01'), 'YYYYMonDD') as src_file_date,
		0.83 as percent_of_payment,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Tucson' as payer_contract,
	from SOURCE_PROD.united.src_united_mmr_hmo_tucson
	
	union all
	
	select
		to_varchar(member_alt_id) as member_id,
		date(payment_date, 'YYYYMM') as payment_month,
		date(apply_date, 'DDMonYYYY') as apply_month,
		gross_revenue,
		nullif(risk_adjuster_factor_a, '0.000') as raf_score,
		adjustment_reason_code,
		default_risk_adj_flg,
		esrd_mbr_msp_flg,
		esrd_flg,
		iff(mcaid_status_flg = 1, true, false) as dual_status_bool,
		risk_adj_factor_typ_cd as raf_type_code,
		risk_adj_factor_typ_cd_desc,
		frailty_flg,
		orig_rsn_for_entitlement as original_reason_entitlement_code,
		concat(contract_nbr, '-', lpad(pbp, 3, '0'), '-', lpad(segment_nbr, 3, '0')) as pbp_code,
		src_file_name,
		'United' as source,
		date(concat(left(split_part(replace(src_file_name, '_RUNOUT', ''), '_', -1), 4), split_part(replace(src_file_name, '_RUNOUT', ''), '_', -2), '01'), 'YYYYMonDD') as src_file_date,
		0.83 as percent_of_payment,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Tucson' as payer_contract,
	from SOURCE_PROD.united.src_united_mmr_ppo_tucson
	
	union all 
	
	select
		to_varchar(member_alt_id) as member_id,
		date(payment_date, 'YYYYMM') as payment_month,
		date(apply_date, 'DDMonYYYY') as apply_month,
		gross_revenue,
		nullif(risk_adjuster_factor_a, '0.000') as raf_score,
		adjustment_reason_code,
		default_risk_adj_flg,
		esrd_mbr_msp_flg,
		esrd_flg,
		iff(mcaid_status_flg = 1, true, false) as dual_status_bool,
		risk_adj_factor_typ_cd as raf_type_code,
		risk_adj_factor_typ_cd_desc,
		frailty_flg,
		orig_rsn_for_entitlement as original_reason_entitlement_code,
		concat(contract_nbr, '-', lpad(pbp, 3, '0'), '-', lpad(segment_nbr, 3, '0')) as pbp_code,
		src_file_name,
		'United' as source,
		date(concat(left(split_part(replace(src_file_name, '_RUNOUT', ''), '_', -1), 4), split_part(replace(src_file_name, '_RUNOUT', ''), '_', -2), '01'), 'YYYYMonDD') as src_file_date,
		0.83 as percent_of_payment,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ DSNP' as payer_contract,
	from SOURCE_PROD.united.src_united_mmr_csp
)
select
	case
		when len(member_id) = 11 then right(replace(member_id, '-1', ''), 7)::varchar || '01'
		else member_id
	end as member_id,
	* exclude (member_id),
	dense_rank() over (partition by year(src_file_date), split(src_file_name, '_')[0] || split(src_file_name, '_')[1] order by src_file_date desc) as mmr_index,
from united_mmr_data
  );

