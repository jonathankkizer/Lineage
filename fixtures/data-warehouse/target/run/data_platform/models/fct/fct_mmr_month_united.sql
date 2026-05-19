
  
    

create or replace transient table dw_dev.dev_jkizer.fct_mmr_month_united
    copy grants
    
    
    as (with all_united_mmr as (
	select * from dw_dev.dev_jkizer_staging.stg_united_az_mmr
	union all
	select * from dw_dev.dev_jkizer_staging.stg_united_tx_mmr
), united_mmr_revenue as (
	select
		member_id,
		apply_month as mmr_month,
		source as mmr_source,
		percent_of_payment,
		payer_parent,
		payer_name,
		payer_contract,
		max(case
			when src_file_name ilike '%SUVDATUCNCE%' then 'Tucson MA'
			when src_file_name ilike '%SUVDAPHXNCE%' then 'Phoenix MA'
			when src_file_name ilike '%SUVIDATUC%' then 'Tucson MA'
			when src_file_name ilike '%SUVIDAPHX%' then 'Phoenix MA'
			when src_file_name ilike '%SUVIDA_CSP%' then 'DSNP'
			when src_file_name ilike '%SUVIDATX%' then 'Texas MA'
		end) as source_lob,
		max(dual_status_bool) as dual_status_bool,
		max(src_file_date) as max_mmr_report_date,
		max(pbp_code) as pbp_code,
		sum(gross_revenue) as mmr_revenue,
	from all_united_mmr
	where mmr_index = 1
	group by all
), united_mmr_raf as (
	select
		member_id,
		apply_month,
		max(payment_month) as payment_month,
	from all_united_mmr
	where mmr_index = 1
	and raf_score <> 0
	group by all
), united_mmr_raf_rollup as (
	select
		mmr.member_id,
		mmr.apply_month as mmr_month,
		mmr.source as mmr_source,
		mpm.payment_month,
		sum(mmr.raf_score) as mmr_risk_score,
		max(raf_type_code) as raf_type_code,
		max(original_reason_entitlement_code) as original_reason_entitlement_code,
	from all_united_mmr mmr
	inner join united_mmr_raf mpm
		on mmr.member_id = mpm.member_id
		and mmr.apply_month = mpm.apply_month
		and mmr.payment_month = mpm.payment_month
	where mmr.mmr_index = 1
	group by all
), united_logic as (
	select 
		umr.member_id,
		umr.mmr_month,
		umr.mmr_source,
		umr.dual_status_bool,
		umr.max_mmr_report_date,
		umr.mmr_revenue * umr.percent_of_payment as mmr_revenue,
		umraf.mmr_risk_score,
		umraf.raf_type_code,
		umraf.original_reason_entitlement_code,
		umr.source_lob,
		umr.pbp_code,
		umr.payer_parent,
		umr.payer_name,
		umr.payer_contract,
	from united_mmr_revenue umr
	left join united_mmr_raf_rollup umraf 
		on umr.member_id = umraf.member_id
		and umr.mmr_month = umraf.mmr_month
)
select
	ul.mmr_month,
	siw.suvida_id,
	null as medicare_beneficiary_id,
	ul.member_id,
	dap.birth_date,
	ul.mmr_source,
	cast(cast(ul.original_reason_entitlement_code as int) as varchar) as original_reason_entitlement_code,
	ul.max_mmr_report_date,
	ul.mmr_risk_score,
	null as mmr_part_d_risk_score,
	ul.raf_type_code,
	ul.mmr_revenue,
	null as mmr_part_d_revenue,
	ul.dual_status_bool,
	ul.source_lob,
	ul.pbp_code,
	ul.payer_parent,
	ul.payer_name,
	ul.payer_contract,
from united_logic ul
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on ul.member_id = siw.member_id
	and ul.mmr_source = siw.source
left join dw_dev.dev_jkizer.dim_assignment_patient dap
	on ul.member_id = dap.member_id
	and ul.mmr_source = dap.source
	and dap.patient_report_index = 1
    )
;


  