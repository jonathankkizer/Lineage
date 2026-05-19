with devoted_enrollment_data as (
	select
		to_varchar(MemberID) as member_id,
		to_varchar(MBI) as mbi,
		'Devoted' as source,
		'Devoted' as payer_parent,
		case 
			when lower(MemberState) = 'tx' then 'Devoted TX'
			when lower(MemberState) = 'az' then 'Devoted AZ'
			else null
		end as payer_name,
		case 
			when lower(MemberState) = 'tx' then 'Devoted TX'
			when lower(MemberState) = 'az' then 'Devoted AZ'
			else null
		end as payer_contract,
		to_varchar(MBI) as medicare_beneficiary_id,
		lower(MemberFirstName) as first_name,
		lower(MemberLastName) as last_name,
		null as middle_name,
		lower(MemberMiddleInitial) as middle_initial,
		date(MemberDOB) as birth_date,
		
    
    case
        when regexp_replace(coalesce(MemberMobilePhone, MemberPhone), '[^0-9]', '') = '' then null
        when length(regexp_replace(coalesce(MemberMobilePhone, MemberPhone), '[^0-9]', '')) = 11
            and left(regexp_replace(coalesce(MemberMobilePhone, MemberPhone), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(coalesce(MemberMobilePhone, MemberPhone), '[^0-9]', ''), 10)
        when length(regexp_replace(coalesce(MemberMobilePhone, MemberPhone), '[^0-9]', '')) = 10
            then regexp_replace(coalesce(MemberMobilePhone, MemberPhone), '[^0-9]', '')
        else null
    end
 as phone,
		lower(MemberEmail) as email,
		lower(MemberLanguage) as language_preference,
		lower(MemberGender) as gender,
		replace(lower(ltrim(rtrim(MemberAddressLine1))), '\t', '') as address_line_1,
		replace(lower(ltrim(rtrim(MemberAddressLine2))), '\t', '') as address_line_2,
		lower(MemberCity) as city,
		lower(MemberState) as state,
		to_varchar(MemberZip) as zip,
		iff(EffectiveMonth is null, null, date(concat(EffectiveMonth, '-01'))) as effective_date,
		date(EnrollmentStartDate) as enrollment_start_date,
		date(EnrollmentEndDate) as enrollment_end_date,
		DualEligibleStatus as dual_eligibility_status,
		iff(DualEligibleStatus > 0, 'Dual', 'Non-Dual') as dual_status,
		Hospice as hospice_ind,
		MemberESRDIndicator as esrd_ind,
		MemberDeathDate as death_date,
		PcpFirstName as provider_first_name,
		PcpLastName as provider_last_name,
		PcpNpi as pcp_npi,
		PcpTIN as pcp_tin,
		e.PlanName as plan_name,
		e.CMSContractPBP as plan_code,
		0 as plan_name_match,
		PlanVariant as plan_variant,
		date(PCPStartDate) as pcp_start_date,
		null as agent_number,
		agentofrecord as agent_info,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
		date(ReportDate) as report_date
	from airbyte_source_prod.devoted.assignment_monthly e
)
select
	*,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	pcp_start_date as suvida_start_date,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from devoted_enrollment_data
where date_trunc(month, effective_date)  = date_trunc(month, report_date)