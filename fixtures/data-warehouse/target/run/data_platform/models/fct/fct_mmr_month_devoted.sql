
  
    

create or replace transient table dw_dev.dev_jkizer.fct_mmr_month_devoted
    copy grants
    
    
    as (with devoted_logic as (
	select
		dd.date_day as mmr_month,
		medicare_beneficiary_id,
		raf_type_code,
		src_file_date,
		coalesce(nullif(part_a_risk_score, 0), nullif(part_b_risk_score, 0)) as risk_score,
		part_d_risk_score,
		original_reason_entitlement_code,
		iff(medicaid_dual_status_code > 0, true, false) as dual_status_bool,
		(
			div0null((part_a_risk_adjustment_monthly_rate * part_a_risk_score), num_months_part_a)
			+
			div0null((part_b_risk_adjustment_monthly_rate * part_b_risk_score), num_months_part_b)
			- (div0null(rebate_for_part_d_supplemental_benefits_part_a, num_months_part_a) + div0null(rebate_for_part_d_supplemental_benefits_part_b, num_months_part_b))
		- 10.00) * .86 as revenue, -- Devoted's MMR revenue flow per contract
		(total_part_d_payment / nullif(num_months_part_d, 0)) as part_d_revenue,
		source as mmr_source,
	from dw_dev.dev_jkizer_staging.stg_devoted_mmr dm
	left join dw_dev.dev_jkizer.dim_date dd
		on dd.date_day between dm.adjustment_start_date and dm.adjustment_end_date
		and dd.is_bom = 1
	qualify dense_rank() over (partition by medicare_beneficiary_id, date_day, payment_date order by run_date desc, src_file_date desc) = 1 -- takes latest record per person, mmr period, and payment date; ordering by adjustment reason code favors non-Part D adjustment types
)
select distinct
	dl.mmr_month,
	siw.suvida_id,
	dl.medicare_beneficiary_id,
	dap.member_id,
	dap.birth_date,
	dl.mmr_source,
	first_value(cast(cast(original_reason_entitlement_code as int) as varchar)) ignore nulls over (partition by dl.mmr_month, dl.medicare_beneficiary_id order by dl.src_file_date desc) as original_reason_entitlement_code,
	max(dl.src_file_date) over (partition by dl.mmr_month, dl.medicare_beneficiary_id) as max_mmr_report_date,
	first_value(dl.risk_score) ignore nulls over (partition by dl.mmr_month, dl.medicare_beneficiary_id order by dl.src_file_date desc) as mmr_risk_score,
	first_value(dl.part_d_risk_score) ignore nulls over (partition by dl.mmr_month, dl.medicare_beneficiary_id order by dl.src_file_date desc) as mmr_part_d_risk_score,
	max(dl.raf_type_code) over (partition by dl.mmr_month, dl.medicare_beneficiary_id) as raf_type_code,
	sum(dl.revenue) over (partition by dl.mmr_month, dl.medicare_beneficiary_id) as mmr_revenue,
	sum(dl.part_d_revenue) over (partition by dl.mmr_month, dl.medicare_beneficiary_id) as mmr_part_d_revenue,
	max(dl.dual_status_bool) over (partition by dl.mmr_month, dl.medicare_beneficiary_id) as dual_status_bool,
	null as source_lob,
	null as pbp_code,
from devoted_logic dl
left join dw_dev.dev_jkizer.dim_assignment_patient dap
	on dl.medicare_beneficiary_id = dap.medicare_beneficiary_id
	and dl.mmr_source = dap.source
	and dap.patient_report_index = 1
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on dap.member_id = siw.member_id
	and dap.source = siw.source
    )
;


  