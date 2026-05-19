
  
    

create or replace transient table dw_dev.dev_jkizer.fct_mmr_month_wellmed
    copy grants
    
    
    as (with wellmed_mmr_month_raf as (
	select distinct
		gmpi_id,
		cap_period_month as mmr_month,
		first_value(raf_score) over (partition by gmpi_id, cap_period_month order by cap_process_month desc, raf_type_code asc) as mmr_risk_score,
	from dw_dev.dev_jkizer_staging.stg_wellmed_mmr
	where cap_entitled_indicator = 'C'
	and raf_score != 0
), wellmed_mmr_month_revenue as (
	select 
		gmpi_id,
		cap_period_month as mmr_month,
		sum(net_payment_amount) as mmr_revenue,
	from dw_dev.dev_jkizer_staging.stg_wellmed_mmr
	where mmr_process_month_report_rank = 1
	group by all
), wellmed_mmr_month_spend as (
	select
		mmr.gmpi_id,
		raf_type_code,
		mmr.period_month as mmr_month,
		original_reason_entitlement_code,
		rev.mmr_revenue,
		-- net_payment_amount as mmr_revenue,
		-- raf_score as mmr_risk_score,
		raf.mmr_risk_score,
		null as part_d_risk_score,
		iff(raf_type_description ilike '%Partial Dual%' or raf_type_description ilike '%Full Dual%', true, false) as dual_status_bool,
		null as frailty_ind,
		src_file_name,
		src_file_date,
		date_trunc(month, src_file_date) as src_file_month,
		source as mmr_source,
	from dw_dev.dev_jkizer_staging.stg_wellmed_mmr mmr
	left join wellmed_mmr_month_raf raf
		on mmr.gmpi_id = raf.gmpi_id
		and mmr.period_month = raf.mmr_month
	left join wellmed_mmr_month_revenue rev 
		on mmr.gmpi_id = rev.gmpi_id
		and mmr.period_month = rev.mmr_month
	where mmr.mmr_process_month_report_rank = 1
	and mmr.capped_count != 0
	qualify row_number() over (partition by mmr.gmpi_id, mmr.period_month order by mmr.process_month desc, mmr.capped_count desc) = 1
)
select
	wmm.mmr_month,
	siw.suvida_id,
	dap.medicare_beneficiary_id,
	dap.member_id,
	dap.birth_date,
	wmm.mmr_source,
	cast(cast(wmm.original_reason_entitlement_code as int) as varchar) as original_reason_entitlement_code,
	wmm.src_file_date as max_mmr_report_date,
	wmm.mmr_risk_score,
	null as mmr_part_d_risk_score,
	wmm.raf_type_code,
	wmm.mmr_revenue * 0.96 as mmr_revenue,
	null as mmr_part_d_revenue,
	wmm.dual_status_bool,
	null as source_lob,
	null as pbp_code,
from wellmed_mmr_month_spend wmm
left join dw_dev.dev_jkizer.dim_assignment_patient dap
	on wmm.gmpi_id = dap.gmpi_id
	and wmm.mmr_source = dap.source
	and dap.patient_report_index = 1
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on dap.member_id = siw.member_id
	and dap.source = siw.source
    )
;


  