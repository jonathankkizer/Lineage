select 
	pfm.suvida_id,
	pfm.financial_member_month,
	pfm.financial_member_month as mmr_month,
	pm.risk_score_performance_year_projection,
	pfm.part_c_net_premium,
	coalesce(pr.mmr_revenue, pr2.mmr_revenue) as mmr_revenue,
	coalesce(pr.mmr_source, pr2.mmr_source) as mmr_source,
	coalesce(pr.member_id, pr2.member_id) as member_id,
	coalesce(pr.medicare_beneficiary_id, pr2.medicare_beneficiary_id) as medicare_beneficiary_id,
	coalesce(pr.original_reason_entitlement_code, pr2.original_reason_entitlement_code) as original_reason_entitlement_code,
	coalesce(pfm.part_c_net_premium, pr.mmr_revenue) as revenue,
	coalesce(pr.mmr_risk_score, pr2.mmr_risk_score) as mmr_risk_score,
	coalesce(to_double(pr.mmr_part_d_risk_score), to_double(pr2.mmr_part_d_risk_score)) as mmr_part_d_risk_score,
	coalesce(pr.raf_type_code, pr2.raf_type_code) as raf_type_code,
	coalesce(pr.mmr_part_d_revenue, pr2.mmr_part_d_revenue) as mmr_part_d_revenue,
	coalesce(pr.hcc_engine_raf_type_description, pr2.hcc_engine_raf_type_description) as raf_description,
	coalesce(pr.hcc_engine_raf_type, pr2.hcc_engine_raf_type) as hcc_engine_raf_type,
	coalesce(div0null(coalesce(pfm.part_c_net_premium, coalesce(pr.mmr_revenue, pr2.mmr_revenue)), coalesce(pr.mmr_risk_score, pr2.mmr_risk_score)) * pm.risk_score_performance_year_projection, coalesce(pfm.part_c_net_premium, coalesce(pr.mmr_revenue, pr2.mmr_revenue))) as projection_adjusted_revenue,
from dw_dev.dev_jkizer.patient_financial_membership pfm
left join dw_dev.dev_jkizer.patient_monthly pm
	on pfm.suvida_id = pm.suvida_id
	and pfm.financial_member_month = pm.period_start_date
left join dw_dev.dev_jkizer.fct_mmr_month pr 
	on pfm.suvida_id = pr.suvida_id
	and pfm.financial_member_month = pr.mmr_month
	and pr.suvida_id_mmr_rank = 1
left join dw_dev.dev_jkizer.fct_mmr_month pr2 
	on pfm.member_id = pr2.member_id
	and pfm.financial_member_month = pr2.mmr_month
	and pr2.suvida_id is null 
	and pr2.member_id_mbi_mmr_rank = 1
where pfm.financial_member_month_ind = 1