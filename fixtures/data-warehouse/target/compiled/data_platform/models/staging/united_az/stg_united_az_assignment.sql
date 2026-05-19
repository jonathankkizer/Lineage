with united_az_assignment_data as (
	select
		data:"CES_ALT_ID"::string as member_id,
		data:"MBI"::string as medicare_beneficiary_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ DSNP' as payer_contract,
		lower(data:"F_NAME"::string) as first_name,
		lower(data:"L_NAME"::string) as last_name,
		to_varchar(null) as middle_name,
		lower(data:"M_INIT"::string) as middle_initial,
		to_date(data:"DOB"::string, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '') = '' then null
        when length(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '')) = 11
            and left(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', ''), 10)
        when length(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '')) = 10
            then regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '')
        else null
    end
 as phone,
		to_varchar(null) as email,
		to_varchar(null) as language_preference,
		lower(data:"GENDER"::string) as gender,
		lower(data:"ADDR1"::string) as address_line_1,
		nullif(lower(data:"ADDR2"::string), '') as address_line_2,
		lower(data:"CITY"::string) as city,
		lower(data:"STATE"::string) as state,
		data:"ZIP"::string as zip,
		to_date(data:"ORIG_EFF"::string, 'MM/DD/YYYY') as original_effective_date,
		to_date(data:"ENR_EFF"::string, 'MM/DD/YYYY') as enrollment_effective_date,
		data:"NPI_NBR"::string as pcp_npi,
		lower(trim(replace(data:"PROVNAME"::string, split_part(data:"PROVNAME"::string, ' ', -1), ''))) as provider_last_name,
		lower(split_part(data:"PROVNAME"::string, ' ', -1)) as provider_first_name,
		data:"PRV_TIN"::string as pcp_tin,
		data:"MEM_PCP_ID"::string as payer_provider_id,
		data:"CONTRACT"::string || '-' || lpad(data:"PBP"::string, 3, '0') || '-' || coalesce(data:"SEGMENT_ID"::string, '000') as plan_code,
		data:"MKP_DESCRIPTION"::string as plan_name,
		0 as plan_name_match,
		to_varchar(null) as plan_variant,
		'Dual' as dual_status,
		null as hospice_ind,
		null as esrd_ind,
		null as agent_number,
		null as agent_info,
		date_trunc(month, to_date(data:"CR_DATE"::string, 'MM/DD/YYYY')) as report_date,
		'assignment_csp' as lob_file,
		'DSNP' as source_lob,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar as src_file_name,
		data as data_variant
	from airbyte_source_prod.united_az.assignment_csp

	union all

	select
		data:"CES_ALT_ID"::string as member_id,
		data:"MBI"::string as medicare_beneficiary_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		case
			when _ab_source_file_url ilike '%phoenix%' then 'United AZ Phoenix'
			when _ab_source_file_url ilike '%tucson%' then 'United AZ Tucson'
		end as payer_contract,
		lower(data:"F_NAME"::string) as first_name,
		lower(data:"L_NAME"::string) as last_name,
		to_varchar(null) as middle_name,
		lower(data:"M_INIT"::string) as middle_initial,
		to_date(data:"DOB"::string, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '') = '' then null
        when length(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '')) = 11
            and left(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', ''), 10)
        when length(regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '')) = 10
            then regexp_replace(data:"HAREA_CD"::string || data:"HPHONE"::string, '[^0-9]', '')
        else null
    end
 as phone,
		to_varchar(null) as email,
		to_varchar(null) as language_preference,
		lower(data:"GENDER"::string) as gender,
		lower(data:"ADDR1"::string) as address_line_1,
		nullif(lower(data:"ADDR2"::string), '') as address_line_2,
		lower(data:"CITY"::string) as city,
		lower(data:"STATE"::string) as state,
		data:"ZIP"::string as zip,
		to_date(data:"ORIG_EFF"::string, 'MM/DD/YYYY') as original_effective_date,
		to_date(data:"ENR_EFF"::string, 'MM/DD/YYYY') as enrollment_effective_date,
		data:"NPI_NBR"::string as pcp_npi,
		lower(trim(split_part(data:"PROVNAME"::string, ',', 1))) as provider_last_name,
		lower(trim(split_part(data:"PROVNAME"::string, ',', -1))) as provider_first_name,
		data:"PRV_TIN"::string as pcp_tin,
		data:"MEM_PCP_ID"::string as payer_provider_id,
		data:"CONTRACT"::string || '-' || lpad(data:"PBP"::string, 3, '0') || '-' || coalesce(data:"SEGMENT_ID"::string, '000') as plan_code,
		data:"MKP_DESCRIPTION"::string as plan_name,
		0 as plan_name_match,
		to_varchar(null) as plan_variant,
		'Non-Dual' as dual_status,
		null as hospice_ind,
		null as esrd_ind,
		null as agent_number,
		null as agent_info,
		date_trunc(month, to_date(data:"CR_DATE"::string, 'MM/DD/YYYY')) as report_date,
		'assignment_cosmos' as lob_file,
		case
			when _ab_source_file_url ilike '%phoenix%' then 'Phoenix MA'
			when _ab_source_file_url ilike '%tucson%' then 'Tucson MA'
		end as source_lob,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar as src_file_name,
		data as data_variant
	from airbyte_source_prod.united_az.assignment_cosmos
)
select
	*,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	enrollment_effective_date as suvida_start_date,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from united_az_assignment_data