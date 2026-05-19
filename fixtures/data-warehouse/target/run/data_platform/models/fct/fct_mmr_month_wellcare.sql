
  
    

create or replace transient table dw_dev.dev_jkizer.fct_mmr_month_wellcare
    copy grants
    
    
    as (with wellcare_risk_score_mmr as (
	select
		dd.date_day as mmr_month,
		medicare_beneficiary_id,
		coalesce(nullif(dm.risk_adjustor_factor_a, 0), nullif(dm.risk_adjustor_factor_b, 0)) as mmr_risk_score,
		dense_rank() over (partition by medicare_beneficiary_id, date_day order by payment_date desc, run_date desc, src_file_date desc) as risk_score_rank,
	from dw_dev.dev_jkizer_staging.stg_wellcare_mmr dm
	left join dw_dev.dev_jkizer.dim_date dd
		on dd.date_day between dm.adjustment_start_date and dm.adjustment_end_date
		and dd.is_bom = 1
	where (risk_adjustor_factor_a != 0 or risk_adjustor_factor_b != 0)
	qualify dense_rank() over (partition by medicare_beneficiary_id, date_day, payment_date order by run_date desc, src_file_date desc, raf_type_code asc) = 1 -- takes latest record per person, mmr period, and payment date; ordering by adjustment reason code favors non-Part D adjustment types
), wellcare_risk_score as (
	select
		activity_month as mmr_month,
		medicare_beneficiary_id,
		mmr_risk_score,
		mmr_part_d_risk_score,
		source as mmr_source,
	from dw_dev.dev_jkizer_staging.stg_wellcare_mmr_demographic dm
	qualify row_number() over (partition by medicare_beneficiary_id, activity_month order by report_date desc, mmr_risk_score asc) = 1
), wellcare_logic as (
	select
		dd.date_day as mmr_month,
		dense_rank() over (partition by medicare_beneficiary_id, date_day order by payment_date desc, run_date desc, src_file_date desc) as risk_score_rank,
		medicare_beneficiary_id,
		raf_type_code,
		src_file_date,
		--coalesce(nullif(dm.risk_adjustor_factor_a, 0), nullif(dm.risk_adjustor_factor_b, 0)) as risk_score,
		null as part_d_risk_score,
		dual_status_bool,
		original_reason_entitlement_code,
		((
			total_ma_payment_amt
			/
			nullif(num_months_part_a, 0) -- distribute payment across number of months it covers
		) -
		(
			(abs(partd_sup_ben_parta_rebate_amt) + abs(partd_sup_ben_partb_rebate_amt) + abs(part_d_basic_premium) + abs(part_d_direct_subsidy_amount)) -- distribute rebate across number of months it covers
			/
			nullif(num_months_part_a, 0)
		)) * 0.845 as revenue,
		source as mmr_source,
	from dw_dev.dev_jkizer_staging.stg_wellcare_mmr dm
	left join dw_dev.dev_jkizer.dim_date dd
		on dd.date_day between dm.adjustment_start_date and dm.adjustment_end_date
		and dd.is_bom = 1
	qualify dense_rank() over (partition by medicare_beneficiary_id, date_day, payment_date order by run_date desc, src_file_date desc, raf_type_code asc) = 1 -- takes latest record per person, mmr period, and payment date; ordering by adjustment reason code favors non-Part D adjustment types
)
select distinct
	coalesce(wrs.mmr_month, wl.mmr_month) as mmr_month,
	siw.suvida_id,
	coalesce(wrs.medicare_beneficiary_id, wl.medicare_beneficiary_id) as medicare_beneficiary_id,
	dap.member_id,
	dap.birth_date,
	coalesce(wrs.mmr_source, wl.mmr_source) as mmr_source,
	first_value(cast(cast(original_reason_entitlement_code as int) as varchar)) ignore nulls over (partition by wl.mmr_month, wl.medicare_beneficiary_id order by wl.src_file_date desc) as original_reason_entitlement_code,
	max(wl.src_file_date) over (partition by wl.mmr_month, wl.medicare_beneficiary_id) as max_mmr_report_date,
	coalesce(wrs.mmr_risk_score, wrs_mmr.mmr_risk_score) as mmr_risk_score,
	wrs.mmr_part_d_risk_score,
	max(iff(wl.risk_score_rank = 1, wl.raf_type_code, null)) over (partition by wl.mmr_month, wl.medicare_beneficiary_id) as raf_type_code,
	sum(wl.revenue) over (partition by wl.mmr_month, wl.medicare_beneficiary_id) as mmr_revenue,
	null as mmr_part_d_revenue,
	max(dual_status_bool) over (partition by wl.mmr_month, wl.medicare_beneficiary_id) as dual_status_bool,
	null as source_lob,
	null as pbp_code,
from wellcare_risk_score wrs
full outer join wellcare_logic wl
	on wl.medicare_beneficiary_id = wrs.medicare_beneficiary_id
	and wl.mmr_month = wrs.mmr_month
left join wellcare_risk_score_mmr wrs_mmr 
	on wl.medicare_beneficiary_id = wrs_mmr.medicare_beneficiary_id
	and wl.mmr_month = wrs_mmr.mmr_month
	and wrs_mmr.risk_score_rank = 1
left join dw_dev.dev_jkizer.dim_assignment_patient dap
	on coalesce(wrs.medicare_beneficiary_id, wl.medicare_beneficiary_id) = dap.medicare_beneficiary_id
	and coalesce(wrs.mmr_source, wl.mmr_source) = dap.source
	and dap.patient_report_index = 1
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on dap.member_id = siw.member_id
	and dap.source = siw.source
    )
;


  