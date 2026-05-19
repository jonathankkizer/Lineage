with patient_claims_dataset as (
	select
		claim_id,
		claim_line_number,
		encounter_id,
		claim_type,
		iff(left(person_id, 9) = 'member_id', null, person_id) as suvida_id,
		member_id,
		payer,
		plan,
		claim_start_date,
		claim_end_date,
		claim_line_start_date,
		claim_line_end_date,
		admission_date,
		discharge_date,
		service_category_1,
		service_category_2,
		admit_source_code,
		admit_type_code,
		place_of_service_code,
		paid_date,
		paid_amount,
		allowed_amount,
		charge_amount,
		coinsurance_amount,
		copayment_amount,
		deductible_amount,
		total_cost_amount,
		data_source,
		tuva_last_run,
		iff(datediff(month, date_trunc(month, claim_start_date), current_date) > 3, true, false) as is_claim_within_last_3_months,
	from suvida_tuva.core.medical_claim
), devoted_claims as (
	select
		pc.suvida_id,
		pc.member_id,
		date_trunc(month, coalesce(pc.claim_line_start_date, pc.admission_date, pc.claim_start_date)) as claim_month,
		pc.claim_type,
		pc.paid_amount,
	from patient_claims_dataset pc
	where pc.payer = 'Devoted'
	and (pc.claim_type = 'institutional' or (pc.claim_type = 'professional' and pc.place_of_service_code != 99)) -- remove supplemental benefits
	and (pc.claim_type = 'institutional' or (pc.claim_type = 'professional' and pc.place_of_service_code is not null)) -- remove supplemental benefits
), wellcare_wellmed_united_claims as (
	select
		pc.suvida_id,
		pc.member_id,
		date_trunc(month, coalesce(pc.claim_line_start_date, pc.admission_date, pc.claim_start_date)) as claim_month,
		pc.claim_type,
		pc.paid_amount,
	from patient_claims_dataset pc
	where pc.payer in ('Wellcare/Centene', 'UHG/Wellmed', 'United', 'United TX')
), all_claims as (
	select *
	from devoted_claims
	union all
	select *
	from wellcare_wellmed_united_claims
	union all
	select
		siw.suvida_id,
		rx.member_id,
		date_trunc(month, rx.claim_start_date) as claim_month,
		rx.claim_type,
		rx.paid_amount
	from dw_dev.dev_jkizer_staging.stg_united_az_rx_claim_rollup rx
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on rx.member_id = siw.member_id
		and siw.source = 'United'
	where claims_report_rank = 1
	union all
	select
		siw.suvida_id,
		rx.member_id,
		date_trunc(month, rx.claim_start_date) as claim_month,
		rx.claim_type,
		rx.paid_amount
	from dw_dev.dev_jkizer_staging.stg_united_tx_rx_claim_rollup rx
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on rx.member_id = siw.member_id
		and siw.source = 'United TX'
	where claims_report_rank = 1
	union all
	select
		siw.suvida_id,
		rx.member_id,
		date_trunc(month, rx.claim_start_date) as claim_month,
		rx.claim_type,
		rx.paid_amount
	from dw_dev.dev_jkizer_staging.stg_wellmed_humana_claim_rollup rx
	left join dw_dev.dev_jkizer.suvida_id_walk siw 
		on rx.member_id = siw.member_id
		and siw.source = 'UHG/Wellmed'
	where rx._rn = 1
), agg_claims as (
	select 
		suvida_id,
		member_id,
		claim_month,
		sum(iff(claim_type = 'institutional', paid_amount, null)) as part_a_claims_expense,
		sum(iff(claim_type = 'professional', paid_amount, null)) as part_b_claims_expense,
	from all_claims
	group by all
), payer_financial_assignment as (
	select distinct
		fmm.member_id,
		fmm.financial_member_month,
		fmm.pcp_npi as financial_npi,
		dp_fin.provider_name as financial_provider_name,
		dp_fin.location_name as financial_location_name,
	from dw_dev.dev_jkizer.intmdt_financial_member_month fmm 
	left join dw_dev.dev_jkizer.dim_provider dp_fin
		on fmm.pcp_npi = dp_fin.npi
	qualify row_number() over (partition by member_id, fmm.financial_member_month order by fmm.source desc) = 1
), member_id_eligibility_start as (
	select
		member_id,
		financial_source,
		min(financial_member_month) as eligibility_start_month,
	from dw_dev.dev_jkizer.patient_financial_membership
	where suvida_id is null
	group by all
), patient_service_location_distances as ( -- grab geo info for the nearest clinic to each patient
		select
			pcp.suvida_id,
			pcp.patient_address_id,
			siw.member_id,
			elation_id,
			distance,
		from dw_dev.dev_jkizer_staging.patient_center_proximity pcp -- break these into sources
		left join dw_dev.dev_jkizer_staging.service_locations sl 
			on pcp.service_location_address_id = sl.id
		left join dw_dev.dev_jkizer_staging.patient_addresses pa 
			on pcp.patient_address_id = pa.address_id and
			   pa.source = 'Google'
		inner join dw_dev.dev_jkizer.suvida_id_walk siw 
			on pcp.suvida_id = siw.suvida_id
			and siw.source not in ('Elation', 'SalesForce')
		qualify dense_rank() over (partition by pcp.suvida_id, pcp.patient_address_id order by distance asc) = 1
), prox_location as (
	select distinct
		sld.member_id,
		sl_prox.service_location_name,
	from patient_service_location_distances sld
	left join dw_dev.dev_jkizer_staging.stg_elation_service_location sl_prox
		on sld.elation_id = sl_prox.service_location_id
	qualify row_number() over (partition by member_id order by service_location_name desc) = 1
), eligibility_year_raf_type as (
	select distinct
		suvida_id,
		raf_type_code as max_first_year_raf,
	from dw_dev.dev_jkizer.fct_mmr_month
	where raf_type_code is not null
	qualify row_number() over (partition by suvida_id order by mmr_month desc) = 1
), eligibility_year_raf_type_member as (
	select distinct
		member_id,
		raf_type_code as max_first_year_raf,
	from dw_dev.dev_jkizer.fct_mmr_month
	where suvida_id is null
	qualify row_number() over (partition by member_id order by mmr_month desc) = 1
), test as (
	select 
		pfm.financial_member_month as financial_month,
		pfm.suvida_id,
		pfm.member_id as payer_membership_id,
		pfm.financial_source as payer,
		coalesce(ps.first_name, pfm.first_name) as first_name,
		coalesce(ps.last_name, pfm.last_name) as last_name,
		coalesce(ps.birth_date, pfm.DOB) as birth_date,
		coalesce(pm.location_name, pfa.financial_location_name, pfm.financial_location_name, pl.service_location_name) as monthly_location_name,
		coalesce(pm.provider_name, pfa.financial_provider_name, pfm.financial_provider_name) as monthly_provider_name,
		pm.is_active_patient as monthly_is_active_patient,
		ps.is_active_patient as current_is_active_patient,
		ps.preferred_language,
		ps.ethnicity,
		pm.age_year as monthly_age_year,
		pm.dual_status_bool as monthly_period_dual_status_bool,
		ps.high_risk_patient,
		pm.projected_year_hcc_engine_raf_type,
		pm.projected_year_hcc_engine_raf_description,
		pm.risk_score_performance_year_projection,
		max(iff(pa.suvida_id is not null, 1, 0)) as eligibility_assignment,
		max(1) as financial_assignment,
		max(coalesce(pr.mmr_risk_score, pr2.mmr_risk_score)) as current_year_raf,
		max(coalesce(pr.mmr_part_d_risk_score, pr2.mmr_part_d_risk_score)) as mmr_part_d_risk_score,
		null as capitation, -- CHECK THIS funding to the payer; nice to have but not necessary (useful for certain scenario analyses)
		sum(coalesce(pfm.part_c_net_premium, 0)) as financial_membership_part_c_net_premium,
		sum(coalesce(pfm.part_d_net_premium, 0)) as financial_membership_part_d_net_premium,
		sum(coalesce(pr.mmr_revenue, pr2.mmr_revenue, 0)) as mmr_part_c_net_premium, -- CHECK THIS funding to the payer - what's taken out before it hits us (e.g., our funding)
		max(coalesce(pr.mmr_part_d_revenue, pr2.mmr_part_d_revenue)) as mmr_part_d_net_premium,
		iff(pfm.financial_source in ('Devoted', 'Wellcare/Centene'), 
			sum(coalesce(pfm.part_c_net_premium, 0)), 
			sum(coalesce(pr.mmr_revenue, pr2.mmr_revenue, 0)))
		as combined_part_c_net_premium,
		iff(pfm.financial_source in ('Devoted', 'Wellcare/Centene'), 
			sum(coalesce(pfm.part_d_net_premium, 0)), 
			max(coalesce(pr.mmr_part_d_revenue, pr2.mmr_part_d_revenue)))
		as combined_part_d_net_premium,
		sum(coalesce(cla.part_a_claims_expense, 0) + coalesce(cla_memb.part_a_claims_expense, 0)) as part_a_claims_expense,
		sum(coalesce(cla.part_b_claims_expense, 0) + coalesce(cla_memb.part_b_claims_expense, 0)) as part_b_claims_expense,
		iff(pfm.suvida_id is null, 1, 0) as no_suvida_id_flag,
		null as assignment_src_file_name,
		coalesce(ps.eligibility_start_month, mies.eligibility_start_month) as eligibility_start_month,
		coalesce(year(ps.eligibility_start_month), year(mies.eligibility_start_month)) as eligibility_start_year,
		pfm.source_lob,
		pfm.part_d_expense,
		coalesce(eyrt.max_first_year_raf, eyrtm.max_first_year_raf) as max_first_year_raf,
		pfm.payer_parent,
		pfm.payer_name,
		pfm.payer_contract,
		pfm.plan_network_type,
		pfm.plan_program_type,
		pfm.plan_network_program_type,
		pfm.plan_name,
		pfm.pbp_code,
		pm.dual_status_bool,
	from dw_dev.dev_jkizer.patient_financial_membership pfm
	left join dw_dev.dev_jkizer.patient_summary ps 
		on pfm.suvida_id = ps.suvida_id
	left join dw_dev.dev_jkizer.patient_monthly pm 
		on pfm.suvida_id = pm.suvida_id
		and pfm.financial_member_month = pm.period_start_date
	left join dw_dev.dev_jkizer.patient_assignment pa 
		on pfm.suvida_id = pa.suvida_id
		and pfm.financial_member_month = pa.date_month
	left join dw_dev.dev_jkizer.patient_revenue pr 
		on pfm.suvida_id = pr.suvida_id
		and pfm.financial_member_month = pr.mmr_month
		and pfm.financial_source = pr.mmr_source
	left join dw_dev.dev_jkizer.patient_revenue pr2
		on pfm.member_id = pr2.member_id
		and pfm.financial_member_month = pr2.mmr_month
		and pr2.suvida_id is null
		and pfm.financial_source = pr2.mmr_source
	left join agg_claims cla
		on pfm.suvida_id = cla.suvida_id
		and pfm.financial_member_month = cla.claim_month
		and pfm.suvida_id is not null
	left join agg_claims cla_memb
		on pfm.member_id = cla_memb.member_id
		and pfm.suvida_id is null
		and pfm.financial_member_month = cla_memb.claim_month
	left join payer_financial_assignment pfa
		on pfm.member_id = pfa.member_id
		and pfm.financial_member_month = pfa.financial_member_month
		and pfm.suvida_id is null
	left join member_id_eligibility_start mies 
		on pfm.member_id = mies.member_id
		and pfm.financial_source = mies.financial_source
	left join prox_location pl 
		on pfm.member_id = pl.member_id
	left join eligibility_year_raf_type eyrt
		on pfm.suvida_id = eyrt.suvida_id
	left join eligibility_year_raf_type_member eyrtm
		on pfm.member_id = eyrtm.member_id
	where pfm.financial_member_month_ind = 1
	group by all
), dedupe as (
	select 
		*, 
		iff(current_year_raf is null or current_year_raf = 0, 'Null/0 Value RAF', 'Non-Null/Non-0 RAF') as current_year_raf_check,
		row_number() over (partition by coalesce(suvida_id, payer_membership_id), financial_month order by payer asc) as dedupe_rn,
		iff(date_trunc('month', financial_month) between dateadd(month, -15, date_trunc(month, current_date())) and dateadd(month, -3, date_trunc(month, current_date())), true, false) as is_claim_rolling_12_window
	from test 
)
select
	financial_month,
	suvida_id,
	payer_membership_id,
	payer,
	first_name,
	last_name,
	monthly_location_name,
	monthly_provider_name,
	risk_score_performance_year_projection,
	eligibility_assignment,
	financial_assignment,
	current_year_raf,
	mmr_part_d_risk_score,
	combined_part_c_net_premium,
	combined_part_d_net_premium,
	part_a_claims_expense,
	part_b_claims_expense,
	part_d_expense,
	source_lob,
	eligibility_start_year,
	monthly_is_active_patient,
	current_is_active_patient,
	preferred_language,
	ethnicity,
	monthly_age_year,
	monthly_period_dual_status_bool,
	high_risk_patient,
	max_first_year_raf,
	plan_network_type,
	plan_program_type,
	plan_network_program_type,
	payer_parent,
	payer_name,
	payer_contract,
	plan_name,
	pbp_code,
	dual_status_bool,
from dedupe d
where dedupe_rn = 1
and payer <> 'Alignment AZ' --Filtering Alignment AZ from Finance Validation until the data is validated.
order by financial_month desc