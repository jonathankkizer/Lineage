with financial_membership as (
	select
		siw.suvida_id,
		dfm.member_id,
		dfm.first_name,
		dfm.last_name, 
		dfm.patient_full_name, 
		dfm.dob,
		dfm.effective_month as financial_member_month,
		dfm.plan_name,
		source_lob,
		dfm.pcp_npi,
		dfm.source,
		dfm.report_date,
		iff(_report_date_index = 1, true, false) as is_most_recent_report,
		dfm.premium_credit as part_c_net_premium,
		null as part_d_net_premium,
		null as part_d_expense,
		dfm.pbpcode as pbp_code,
		left(replace(dfm.pbpcode, '-', ''), 8) as contract_plan_id,
		case
			when lower(coalesce(cpsc.plan_name, dfm.plan_name)) ilike '%hmo%' then 'HMO' 
			when lower(coalesce(cpsc.plan_name, dfm.plan_name)) ilike '%ppo%' then 'PPO' 
			else 'Other' 
		end as plan_network_type,
		case
			when lower(coalesce(cpsc.plan_name, dfm.plan_name)) ilike '%D-SNP%' then 'DSNP'
			when lower(coalesce(cpsc.plan_name, dfm.plan_name)) ilike '%C-SNP%' then 'CSNP'
			else 'MA'
		end as plan_program_type,
		plan_network_type || ' - ' || plan_program_type as plan_network_program_type,
		payer_parent,
		payer_name,
		payer_contract,
	from dw_dev.dev_jkizer_staging.stg_devoted_financial_membership dfm
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on dfm.member_id = siw.member_id
		and dfm.source = siw.source
	left join dw_dev.dev_jkizer_staging.stg_cms_cpsc_contract_info cpsc
		on left(replace(dfm.pbpcode, '-', ''), 8) = cpsc.contract_plan_id
		and year(financial_member_month) = year(cpsc.src_file_date)
		and cpsc.year_file_rank = 1
	
	union all
	
	select
		siw.suvida_id,
		dwm.member_id,
		dwm.first_name, 
		dwm.last_name,
		dwm.patient_full_name, 
		dwm.dob,
		dwm.effective_month as financial_member_month,
		dwm.plan_name,
		dwm.source_lob,
		dwm.pcp_npi,
		dwm.source,
		dwm.report_date,
		iff(report_rank = 1, true, false) as is_most_recent_report,
		null as part_c_net_premium,
		null as part_d_net_premium,
		null as part_d_expense,
		dwm.plan_id as pbp_code,
		replace(dwm.plan_id, '-', '') as contract_plan_id,
		case
			when lower(coalesce(cpsc.plan_name, dwm.plan_name)) ilike '%hmo%' then 'HMO' 
			when lower(coalesce(cpsc.plan_name, dwm.plan_name)) ilike '%ppo%' then 'PPO' 
			else 'Other' 
		end as plan_network_type,
		case
			when lower(coalesce(cpsc.plan_name, dwm.plan_name)) ilike '%D-SNP%' then 'DSNP'
			when lower(coalesce(cpsc.plan_name, dwm.plan_name)) ilike '%C-SNP%' then 'CSNP'
			else 'MA'
		end as plan_program_type,
		plan_network_type || ' - ' || plan_program_type as plan_network_program_type,
		payer_parent,
		payer_name,
		payer_contract,
	from dw_dev.dev_jkizer_staging.stg_wellmed_financial_membership dwm
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on dwm.member_id = siw.member_id
		and dwm.source = siw.source
	left join dw_dev.dev_jkizer_staging.stg_cms_cpsc_contract_info cpsc
		on replace(dwm.plan_id, '-', '') = cpsc.contract_plan_id
		and year(financial_member_month) = year(src_file_date)
		and cpsc.year_file_rank = 1
	
	union all
	
	select
		siw.suvida_id,
		wfm.member_id,
		wfm.first_name,
		wfm.last_name, 
		wfm.patient_full_name,
		wfm.dob,
		wfm.activity_date as financial_member_month,
		null as plan_name, --Wellcare does not provide product type in their financial files
		wfm.line_of_business as source_lob,
		wfm.pcp_npi,
		wfm.source,
		wfm.report_date,
		iff(_report_date_index = 1, true, false) as is_most_recent_report,
		part_c_net_premium,
		part_d_net_premium,
		part_d_expense,
		null as pbp_code,
		null as contract_plan_id,
		null as plan_network_type,
		null as plan_program_type,
		null as plan_network_program_type,
		payer_parent,
		payer_name,
		payer_contract,
	from dw_dev.dev_jkizer_staging.stg_wellcare_financial_membership wfm
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on wfm.member_id = siw.member_id
		and wfm.source = siw.source

	union all

	select
		afm.suvida_id,
		afm.member_id,
		afm.first_name,
		afm.last_name,
		afm.patient_full_name,
		afm.dob,
		afm.effective_month as financial_member_month,
		null as plan_name,
		afm.source_lob,
		afm.pcp_npi,
		afm.source,
		afm.report_date,
		iff(afm.report_date_index = 1, true, false) as is_most_recent_report,
		afm.premium_credit as part_c_net_premium,
		null as part_d_net_premium,
		null as part_d_expense,
		afm.pbp_code,
		afm.contract_plan_id,
		case
			when lower(cpsc.plan_name) ilike '%hmo%' then 'HMO'
			when lower(cpsc.plan_name) ilike '%ppo%' then 'PPO'
			else 'Other'
		end as plan_network_type,
		case
			when lower(cpsc.plan_name) ilike '%D-SNP%' then 'DSNP'
			when lower(cpsc.plan_name) ilike '%C-SNP%' then 'CSNP'
			else 'MA'
		end as plan_program_type,
		plan_network_type || ' - ' || plan_program_type as plan_network_program_type,
		afm.payer_parent,
		afm.payer_name,
		afm.payer_contract,
	from dw_dev.dev_jkizer.intmdt_alignment_financial_membership afm
	left join dw_dev.dev_jkizer_staging.stg_cms_cpsc_contract_info cpsc
		on afm.contract_plan_id = cpsc.contract_plan_id
		and year(afm.effective_month) = year(cpsc.src_file_date)
		and cpsc.year_file_rank = 1
)
select
	fm.*
from financial_membership fm