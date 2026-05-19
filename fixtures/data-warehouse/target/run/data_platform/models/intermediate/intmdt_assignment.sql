
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_assignment
    copy grants
    
    
    as (with devoted_monthly as ( -- combine 
	select 
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		null as gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		email,
		language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		hospice_ind,
		esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		null as payer_provider_id,
		plan_name,
		plan_code,
		regexp_substr(replace(plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		plan_name_match,
		plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date,
		src_file_name,
		dense_rank() over (partition by source order by de.report_date desc) as report_index,
		dense_rank() over (partition by de.member_id order by de.report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		null as lob_file,
		state as source_lob,
	from dw_dev.dev_jkizer_staging.stg_devoted_enrollment de
	qualify dense_rank() over (partition by date_trunc(month, report_date) order by report_date desc) = 1 -- latest report for a given month
), devoted_full_elig as ( -- add daily file w/ adds for current month to monthly file, marking each appropriately
	select
		ec.member_id,
		ec.member_file_skey,
		ec.provider_file_skey,
		ec.medicare_beneficiary_id,
		null as gmpi_id,
		ec.first_name,
		ec.last_name,
		ec.middle_name,
		ec.middle_initial,
		ec.birth_date,
		ec.age_year,
		ec.phone,
		ec.email,
		null as language_preference,
		ec.gender,
		ec.address_line_1,
		ec.address_line_2,
		ec.city,
		ec.state,
		ec.zip,
		null as dual_status,
		null as hospice_ind,
		null as esrd_ind,
		ec.provider_first_name,
		ec.provider_last_name,
		ec.pcp_npi,
		null as payer_provider_id,
		ec.plan_name,
		ec.plan_code,
		regexp_substr(replace(ec.plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		ec.plan_name_match,
		null as plan_variant,
		to_varchar(ec.agent_number) as agent_number,
		ec.agent_info,
		ec.source,
		ec.payer_parent,
		ec.payer_name,
		ec.payer_contract,
		ec.report_date,
		ec.src_file_name,
		dense_rank() over (partition by ec.source order by ec.report_date desc) as report_index,
		dense_rank() over (partition by ec.member_id order by ec.report_date desc) as patient_report_index,
		ec.suvida_start_date,
		date_trunc(month, ec.report_date) as report_month,
		null as lob_file,
		ec.state as source_lob,
	from dw_dev.dev_jkizer_staging.stg_devoted_enrollment_change ec
	left join devoted_monthly dm 
		on ec.member_id = dm.member_id
	where ec.status in ('NEW_ENROLLMENT','NEW_TO_PROVIDER_GROUP') -- restrict to new patients only
	and ec.effective_date in (date_trunc(month, ec.report_date), dateadd(month, 1, date_trunc(month, ec.report_date)),dateadd(month, 2, date_trunc(month, ec.report_date)), dateadd(month, 3, date_trunc(month, ec.report_date))) -- only pull current month effectives
	and dm.member_id is null -- prefer the monthly report over the daily file where there is overlap
	qualify dense_rank() over (partition by date_trunc(month, ec.report_date) order by ec.report_date desc) = 1 -- latest report for a given month

	union all 
	
	select
		*
	from devoted_monthly
), wellmed_elig as (
	select 
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		null as email,
		language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		null as hospice_ind,
		null as esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		null as payer_provider_id,
		plan_name,
		plan_code,
		regexp_substr(replace(plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		plan_name_match,
		null as plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date,
		src_file_name,
		dense_rank() over (partition by source order by we.report_date desc) as report_index,
		dense_rank() over (partition by we.member_id order by we.report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		null as lob_file,
		null as source_lob,
	from dw_dev.dev_jkizer_staging.stg_wellmed_enrollment we
	qualify dense_rank() over (partition by date_trunc(month, report_date) order by report_date desc) = 1 -- latest report for a given month
), wellcare_elig as (
	select 
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		null as gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		null as email,
		null as language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		null as hospice_ind,
		null as esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		provider_id as payer_provider_id,
		plan_name,
		plan_code,
		regexp_substr(replace(plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		plan_name_match,
		null as plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date,
		src_file_name,
		dense_rank() over (partition by source order by we.report_date desc) as report_index,
		dense_rank() over (partition by we.member_id order by we.report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		null as lob_file,
		line_of_business as source_lob,
	from dw_dev.dev_jkizer_staging.stg_wellcare_enrollment we
	qualify dense_rank() over (partition by member_id, date_trunc(month, report_date) order by report_date desc) = 1 -- latest report for a given patient and month; differs for Wellcare as patients on any file appear to still have payment
), wellcare_az_elig as (
	select
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		null as gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		email,
		language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		hospice_ind,
		esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		payer_provider_id,
		plan_name,
		plan_code,
		regexp_substr(replace(plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		plan_name_match,
		plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date,
		src_file_name,
		dense_rank() over (partition by source order by wa.report_date desc) as report_index,
		dense_rank() over (partition by wa.member_id order by wa.report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		null as lob_file,
		null as source_lob,
	from dw_dev.dev_jkizer_staging.stg_wellcare_az_assignment wa
	qualify dense_rank() over (partition by member_id, date_trunc(month, report_date) order by report_date desc) = 1
), united_elig as (
	select 
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		null as gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		null as email,
		language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		null as hospice_ind,
		null as esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		null as payer_provider_id,
		plan_name,
		plan_code,
		regexp_substr(replace(plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		plan_name_match,
		null as plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date,
		src_file_name,
		dense_rank() over (partition by source order by we.report_date desc) as report_index,
		dense_rank() over (partition by we.member_id order by we.report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		lob_file,
		source_lob,
	from dw_dev.dev_jkizer_staging.stg_united_az_enrollment we
	qualify dense_rank() over (partition by source_lob, date_trunc(month, report_date) order by report_date desc) = 1 -- latest report for a given month
), united_tx_elig as (
	select
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		null as gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		email,
		language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		hospice_ind,
		esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		payer_provider_id,
		plan_name,
		plan_code,
		regexp_substr(replace(plan_code, '-', ''), '([^0-9].{0,7})', 1, 1, 'e', 1) as contract_plan_id,
		plan_name_match,
		plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date,
		src_file_name,
		dense_rank() over (partition by source order by ut.report_date desc) as report_index,
		dense_rank() over (partition by ut.member_id order by ut.report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		null as lob_file,
		null as source_lob,
	from dw_dev.dev_jkizer_staging.stg_united_tx_assignment ut
	qualify dense_rank() over (partition by member_id, date_trunc(month, report_date) order by report_date desc) = 1
), alignment_data as (
	select 
		member_id,
		member_file_skey,
		provider_file_skey,
		medicare_beneficiary_id,
		null as gmpi_id,
		first_name,
		last_name,
		middle_name,
		middle_initial,
		birth_date,
		age_year,
		phone,
		null as email,
		language_preference,
		gender,
		address_line_1,
		address_line_2,
		city,
		state,
		zip,
		dual_status,
		null as hospice_ind,
		null as esrd_ind,
		provider_first_name,
		provider_last_name,
		pcp_npi,
		null as payer_provider_id,
		null as plan_name,
		payer_plan_code as plan_code,
		contract_plan_id,
		null as plan_name_match,
		null as plan_variant,
		to_varchar(agent_number) as agent_number,
		agent_info,
		source,
		payer_parent,
		payer_name,
		payer_contract,
		report_date as report_date,
		src_file_name as src_file_name,
		dense_rank() over (partition by source order by report_date desc) as report_index,
		dense_rank() over (partition by member_id order by report_date desc) as patient_report_index,
		suvida_start_date,
		date_trunc(month, report_date) as report_month,
		lob_file,
		source_lob,
	from dw_dev.dev_jkizer_staging.stg_alignment_assignment
	qualify dense_rank() over (partition by date_trunc(month, report_date) order by report_date desc) = 1 -- latest report for a given month
), all_data as (
	select *
	from devoted_full_elig
	union all
	select *
	from wellmed_elig
	union all
	select *
	from wellcare_elig
	union all
	select *
	from wellcare_az_elig
	union all
	select *
	from united_elig
	group by all
	union all
	select *
	from united_tx_elig
	union all
	select *
	from alignment_data
), standardize_plan_name as (
	select
		ad.* exclude (plan_name, plan_name_match, payer_name),
		coalesce(cpsc1.plan_name, cpsc2.plan_name, pn.plan_name, ad.plan_name, pn2.plan_name) as plan_name,
		--pc.contract_plan_id,
		iff(pn.plan_code is not null or pn2.plan_code is not null or cpsc1.contract_plan_id is not null or cpsc2.contract_plan_id is not null, 1, 0) as plan_name_match,
		iff(
			ad.payer_name = 'Wellmed/UHG' and (
			(coalesce(cpsc1.organization_marketing_name, cpsc2.organization_marketing_name) = 'Humana')
			or pn.payer_name = 'Humana/Wellmed'), 
			'Wellmed/Humana', 
			ad.payer_name) 
		as payer_name,
		iff(cpsc1.contract_plan_id is not null or cpsc2.contract_plan_id is not null, true, false) as is_cms_cpsc_match,
	from all_data ad
	left join dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_code pc
		on ad.plan_code = pc.formatted_plan_code
	left join dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_name pn
		on pc.unique_plan_code = pn.plan_code
		and pn.plan_year = year(ad.report_date)
	left join dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_name pn2
		on pc.unique_plan_code = pn2.plan_code
		and pn2._rn = 1
	left join dw_dev.dev_jkizer_staging.stg_cms_cpsc_contract_info cpsc1
		on ad.contract_plan_id = cpsc1.contract_plan_id
		--and year(ad.report_date) = year(cpsc1.src_file_date)
		and cpsc1.contract_plan_id_rank = 1
	left join dw_dev.dev_jkizer_staging.stg_cms_cpsc_contract_info cpsc2
		on pc.contract_plan_id = cpsc2.contract_plan_id
		and year(ad.report_date) = year(cpsc2.src_file_date)
		and cpsc2.contract_plan_id_rank = 1
)
select
	* exclude (dual_status, patient_report_index),
	iff(dual_status = 'Dual' or lower(plan_name) like '%d-snp%', 'Dual', 'Non-Dual') as dual_status,
	case
		when plan_name ilike '%hmo%' then 'HMO'
		when plan_name ilike '%ppo%' then 'PPO'
		else 'Other'
	end as plan_network_type,
	case
		when plan_name ilike '%D-SNP%' then 'DSNP'
		when plan_name ilike '%C-SNP%' then 'CSNP'
		else 'MA'
	end as plan_program_type,
	plan_network_type || ' - ' || plan_program_type as plan_network_program_type,
	dense_rank() over (partition by source, member_id order by report_date desc) as patient_report_index,
from standardize_plan_name
    )
;


  