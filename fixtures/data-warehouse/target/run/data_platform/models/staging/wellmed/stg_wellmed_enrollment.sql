
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellmed_enrollment
  
  copy grants
  
  
  as (
    with wellmed_eligibility_data as (
	
	select
		data:MEMBER_SUBSCRIBER_ID::varchar as member_id,
		to_varchar(data:MEMBER_MBI::varchar) as mbi,
		data:GMPI_ID::varchar as gmpi_id,
		'UHG/Wellmed' as source,
		'Wellmed' as payer_parent,
		'Wellmed/UHG' as payer_name,
		'Wellmed' as payer_contract,
		to_varchar(data:MEMBER_MBI::varchar) as medicare_beneficiary_id,
		lower(data:MEMBER_FIRST_NAME::varchar) as first_name,
		lower(data:MEMBER_LAST_NAME::varchar) as last_name,
		to_varchar(null) as middle_name,
		lower(data:MEMBER_MIDDLE_INITIAL::varchar) as middle_initial,
		to_date(nullif(data:MEMBER_DOB::varchar, ''), 'YYYYMMDD') as birth_date,
		
    
    case
        when regexp_replace(data:MEMBER_PHONE::varchar, '[^0-9]', '') = '' then null
        when length(regexp_replace(data:MEMBER_PHONE::varchar, '[^0-9]', '')) = 11
            and left(regexp_replace(data:MEMBER_PHONE::varchar, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(data:MEMBER_PHONE::varchar, '[^0-9]', ''), 10)
        when length(regexp_replace(data:MEMBER_PHONE::varchar, '[^0-9]', '')) = 10
            then regexp_replace(data:MEMBER_PHONE::varchar, '[^0-9]', '')
        else null
    end
 as phone,
		data:SPOKEN_LANGUAGE::varchar as language_preference,
		lower(data:MEMBER_SEX::varchar) as gender,
		replace(lower(ltrim(rtrim(data:MEMBER_ADDR1::varchar))), '\t', '') as address_line_1,
		replace(lower(ltrim(rtrim(data:MEMBER_ADDR2::varchar))), '\t', '') as address_line_2,
		lower(data:MEMBER_CITY::varchar) as city,
		lower(data:MEMBER_STATE::varchar) as state,
		to_varchar(data:MEMBER_ZIP::varchar) as zip,
		date(nullif(data:PLAN_EFFECTIVE_DATE::varchar, '')) as effective_date,
		date(nullif(data:PCP_EFFECTIVE_DATE::varchar, '')) as enrollment_start_date,
		date(nullif(data:PCP_TERM_DATE::varchar, '')) as enrollment_end_date,
		data:PCP_NPI_NBR::varchar as pcp_npi,
		to_varchar(split(replace(data:PCP_NAME::varchar, ' MD', ''), ', ')[0]) as provider_last_name,
		to_varchar(split(replace(data:PCP_NAME::varchar, ' MD', ''), ', ')[1]) as provider_first_name,
		data:PCP_TAX_ID::varchar as pcp_tin,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
		data:BENEFIT_PLAN_CODE::varchar as plan_code,
		null as plan_name,
		0 as plan_name_match,
		iff(data:BENEFIT_PLAN_CODE::varchar in ('2023H4514013001','2023H4514016','2023R6801011H','2023H4514018','2023H4514016K','2023H4527003','2023H4514013002','2023H4590020','2023R6801011D','2023H2228041','2023H0028044','H0609052','H0609064','H4514013001','H4514013002','H4514016','H4514018','H4514021','R6801011'), 'Dual', 'Non-Dual') as dual_status,
		date(nullif(data:CR_DATE::varchar, '')) as report_date
	from airbyte_source_prod.wellmed.assignment e

)
select 
	*,
	null as agent_number,
	null as agent_info,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	enrollment_start_date as suvida_start_date,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from wellmed_eligibility_data
  );

