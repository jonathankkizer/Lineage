with wellcare_az_assignment as (
	select
		data:MEMBER_AMISYS_NBR::varchar as member_id,
		data:MDCR_BNFCRY_ID::varchar as medicare_beneficiary_id,
		lower(data:MEMBER_FIRST_NAME::varchar) as first_name,
		lower(data:MEMBER_LAST_NAME::varchar) as last_name,
		to_varchar(null) as middle_name,
		to_varchar(null) as middle_initial,
		try_to_date(data:MEMBER_DOB::varchar) as birth_date,
		
    
    case
        when regexp_replace(data:MEMBER_PRIMARY_PHONE::varchar, '[^0-9]', '') = '' then null
        when length(regexp_replace(data:MEMBER_PRIMARY_PHONE::varchar, '[^0-9]', '')) = 11
            and left(regexp_replace(data:MEMBER_PRIMARY_PHONE::varchar, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(data:MEMBER_PRIMARY_PHONE::varchar, '[^0-9]', ''), 10)
        when length(regexp_replace(data:MEMBER_PRIMARY_PHONE::varchar, '[^0-9]', '')) = 10
            then regexp_replace(data:MEMBER_PRIMARY_PHONE::varchar, '[^0-9]', '')
        else null
    end
 as phone,
		to_varchar(data:MBR_EMAIL::varchar) as email,
		to_varchar(null) as language_preference,
		lower(data:MEMBER_SEX::varchar) as gender,
		replace(lower(ltrim(rtrim(data:MEMBER_ADDRESS_LINE_1::varchar))), '\t', '') as address_line_1,
		nullif(replace(lower(ltrim(rtrim(data:MEMBER_ADDRESS_LINE_2::varchar))), '\t', ''), '') as address_line_2,
		lower(data:MEMBER_CITY_NAME::varchar) as city,
		lower(data:MEMBER_STATE_CODE::varchar) as state,
		to_varchar(data:MEMBER_POSTAL_CODE::varchar) as zip,
		iff(data:PRODUCT_CATEGORY::varchar = 'DSNP', 'Dual', 'Non-Dual') as dual_status,
		null as hospice_ind,
		null as esrd_ind,
		data:PROV_FIRST_NAME::varchar as provider_first_name,
		data:PROV_LAST_NAME::varchar as provider_last_name,
		data:PROV_NPI::varchar as pcp_npi,
		null as payer_provider_id,
		data:BENEFIT_PACKAGE_DESC::varchar as plan_name,
		regexp_substr(data:BENEFIT_PACKAGE_DESC::varchar, 'H\\d{4}-\\d{3}') as plan_code,
		0 as plan_name_match,
		null as plan_variant,
		null as agent_number,
		null as agent_info,
		'Wellcare AZ' as source,
		'Wellcare' as payer_parent,
		'Wellcare AZ' as payer_name,
		'Wellcare AZ' as payer_contract,
		try_to_date(data:ELIGIBILITY_EFF_DATE::varchar) as suvida_start_date,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar as src_file_name,
		try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}') || '-01', 'YYYY-MM-DD') as report_date,
		data as data_variant
	from airbyte_source_prod.wellcare_az.assignment
)
select
	*,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from wellcare_az_assignment