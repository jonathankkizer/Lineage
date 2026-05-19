
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_tx_assignment
  
  copy grants
  
  
  as (
    with united_tx_assignment as (
	select
		data:"CES_ALT_ID"::string as member_id,
		data:"MBI"::string as medicare_beneficiary_id,
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
		'Non-Dual' as dual_status,
		to_varchar(null) as hospice_ind,
		to_varchar(null) as esrd_ind,
		lower(trim(split_part(data:"PROVNAME"::string, ',', -1))) as provider_first_name,
		lower(trim(split_part(data:"PROVNAME"::string, ',', 1))) as provider_last_name,
		data:"NPI_NBR"::string as pcp_npi,
		data:"MEM_PCP_ID"::string as payer_provider_id,
		data:"MKP_DESCRIPTION"::string as plan_name,
		data:"CONTRACT"::string || '-' || lpad(data:"PBP"::string, 3, '0') || '-' || coalesce(data:"SEGMENT_ID"::string, '000') as plan_code,
		0 as plan_name_match,
		to_varchar(null) as plan_variant,
		to_varchar(null) as agent_number,
		to_varchar(null) as agent_info,
		'United TX' as source,
		'United' as payer_parent,
		'United TX' as payer_name,
		'United TX PPO' as payer_contract,
		to_date(data:"ENR_EFF"::string, 'MM/DD/YYYY') as suvida_start_date,
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar as src_file_name,
		coalesce(
			try_to_date(regexp_substr(_ab_source_file_url, '\\d{8}'), 'MMDDYYYY'),
			date_trunc(month, to_date(data:"CR_DATE"::string, 'MM/DD/YYYY'))
		) as report_date,
		data as data_variant
	from airbyte_source_prod.united_tx.assignment
)
select
	*,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from united_tx_assignment
  );

