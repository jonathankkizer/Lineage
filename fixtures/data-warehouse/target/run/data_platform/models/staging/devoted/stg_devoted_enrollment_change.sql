
  create or replace   view dw_dev.dev_jkizer_staging.stg_devoted_enrollment_change
  
  copy grants
  
  
  as (
    with devoted_enrollment_change as (
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
		MBI as mbi_id,
		to_varchar(MBI) as medicare_beneficiary_id,
		lower(MemberFirstName) as first_name,
		lower(MemberLastName) as last_name,
		lower(MemberMiddleName) as middle_name,
		null as middle_initial,
		date(MemberDOB) as birth_date,
		lower(MemberGender) as gender,
		
    
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
		replace(lower(ltrim(rtrim(MemberAddressLine1))), '\t', '') as address_line_1,
		replace(lower(ltrim(rtrim(MemberAddressLine2))), '\t', '') as address_line_2,
		lower(MemberCity) as city,
		lower(MemberState) as state,
		to_varchar(MemberZip) as zip,
		date(EffectiveDate) as effective_date,
		date(EnrollmentEndDate) as enrollment_end_date,
		PcpFirstName as provider_first_name,
		PcpLastName as provider_last_name,
		PcpNpi as pcp_npi,
		PcpTIN as pcp_tin,
		Status as status,
		DevotedPlan as plan_code,
		DevotedPlanName as plan_name,
		0 as plan_name_match,
		null as agent_number,
		null as agent_info,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
		date(ReportDate) as report_date
	from airbyte_source_prod.devoted.assignment_daily e
)
select
	*,
	effective_date as suvida_start_date,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from devoted_enrollment_change
  );

