
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_az_enrollment
  
  copy grants
  
  
  as (
    with united_enrollment_data as (
	select
		CES_ALT_ID as member_id,
		to_varchar(MBI) as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ DSNP' as payer_contract,
		lower(F_NAME) as first_name,
		lower(L_NAME) as last_name,
		null as middle_name,
		lower(M_INIT) as middle_initial,
		to_date(DOB, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '') = '' then null
        when length(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')) = 11
            and left(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', ''), 10)
        when length(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')) = 10
            then regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')
        else null
    end
 as phone,
		null as language_preference,
		lower(GENDER) as gender,
		lower(ADDR1) as address_line_1,
		lower(ADDR2) as address_line_2,
		lower(ue.CITY) as city,
		lower(ue.STATE) as state,
		to_varchar(ZIP) as zip,
		to_date(ORIG_EFF, 'MM/DD/YYYY') as original_effective_date,
		to_date(ENR_EFF, 'MM/DD/YYYY') as enrollment_effective_date, -- suvida start date
		to_varchar(NPI_NBR) as pcp_npi,
		lower(trim(replace(PROVNAME, split_part(PROVNAME, ' ', -1), ''))) as provider_last_name,
		lower(split_part(PROVNAME, ' ', -1)) as provider_first_name,
		PRV_TIN as pcp_tin,
		src_file_name,
		ue.CONTRACT || '-' || LPAD(ue.PBP, 3, '0') || '-' || coalesce(ue.SEGMENT_ID, '000') as plan_code,
		MKP_DESCRIPTION as plan_name,
		0 as plan_name_match,
		'Dual' as dual_status,
		date_trunc(month, to_date(CR_DATE, 'MM/DD/YYYY')) as report_date,
		'csp' as lob_file,
		'DSNP' as source_lob,
	from SOURCE_PROD.united.src_united_enrollment_csp ue -- CSP is the dual population

	union all

	select
		data:"CES_ALT_ID"::string as member_id,
		data:"MBI"::string as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ DSNP' as payer_contract,
		lower(data:"F_NAME"::string) as first_name,
		lower(data:"L_NAME"::string) as last_name,
		null as middle_name,
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
		null as language_preference,
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
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar as src_file_name,
		data:"CONTRACT"::string || '-' || lpad(data:"PBP"::string, 3, '0') || '-' || coalesce(data:"SEGMENT_ID"::string, '000') as plan_code,
		data:"MKP_DESCRIPTION"::string as plan_name,
		0 as plan_name_match,
		'Dual' as dual_status,
		coalesce(
			try_to_date(regexp_substr(_ab_source_file_url, '\\d{8}'), 'MMDDYYYY'),
			date_trunc(month, to_date(data:"CR_DATE"::string, 'MM/DD/YYYY'))
		) as report_date,
		'csp' as lob_file,
		'DSNP' as source_lob,
	from airbyte_source_prod.united_az.assignment_csp

	union all

	select
		MEMBER_ID as member_id,
		to_varchar(MBI) as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Phoenix' as payer_contract,
		lower(FIRST_NAME) as first_name,
		lower(LAST_NAME) as last_name,
		null as middle_name,
		lower(middle_initial) as middle_initial,
		to_date(DOB, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '') = '' then null
        when length(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '')) = 11
            and left(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', ''), 10)
        when length(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '')) = 10
            then regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '')
        else null
    end
 as phone,
		null as language_preference,
		lower(GENDER) as gender,
		lower(STREET_ADDRESS) as address_line_1,
		null as address_line_2,
		lower(ue.CITY) as city,
		lower(ue.STATE) as state,
		to_varchar(ue.ZIP_CODE) as zip,
		to_date(FIRST_ELIG_EFFECTIVE_DAY, 'YYYYMMDD') as original_effective_date,
		to_date(PCP_FIRST_EFFECTIVE_DAY, 'YYYYMMDD') as enrollment_effective_date, -- suvida start date
		to_varchar(NPI_NBR) as pcp_npi,
		lower(split(PCP_NAME, ', ')[0]) as provider_last_name,
		lower(split(PCP_NAME, ', ')[1]) as provider_last_name,
		PCP_TIN as pcp_tin,
		src_file_name,
		ue.CONTRACT || '-' || LPAD(ue.PBP, 3, '0') || '-' || coalesce(ue.SEGMENT_ID, '000') as plan_code,
		PURCHASER_NAME as plan_name,
		0 as plan_name_match,
		'Non-Dual' as dual_status,
		date_trunc(month, to_date(REPORT_RUN_DATE, 'YYYYMMDD')) as report_date,
		'hmo_phoenix' as lob_file,
		'Phoenix MA' as source_lob,
	from SOURCE_PROD.united.src_united_enrollment_hmo_phoenix ue
	
	union all

	select
		MEMBER_ID as member_id,
		to_varchar(MBI) as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Tucson' as payer_contract,
		lower(FIRST_NAME) as first_name,
		lower(LAST_NAME) as last_name,
		null as middle_name,
		lower(middle_initial) as middle_initial,
		to_date(DOB, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '') = '' then null
        when length(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '')) = 11
            and left(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', ''), 10)
        when length(regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '')) = 10
            then regexp_replace(to_varchar(AREA_CODE) || to_varchar(PHONE_NUMBER), '[^0-9]', '')
        else null
    end
 as phone,
		null as language_preference,
		lower(GENDER) as gender,
		lower(STREET_ADDRESS) as address_line_1,
		null as address_line_2,
		lower(ue.CITY) as city,
		lower(ue.STATE) as state,
		to_varchar(ue.ZIP_CODE) as zip,
		to_date(FIRST_ELIG_EFFECTIVE_DAY, 'YYYYMMDD') as original_effective_date,
		to_date(PCP_FIRST_EFFECTIVE_DAY, 'YYYYMMDD') as enrollment_effective_date, -- suvida start date
		to_varchar(NPI_NBR) as pcp_npi,
		lower(split(PCP_NAME, ', ')[0]) as provider_last_name,
		lower(split(PCP_NAME, ', ')[1]) as provider_last_name,
		PCP_TIN as pcp_tin,
		src_file_name,
		ue.CONTRACT || '-' || LPAD(ue.PBP, 3, '0') || '-' || coalesce(ue.SEGMENT_ID, '000') as plan_code,
		PURCHASER_NAME as plan_name,
		0 as plan_name_match,
		'Non-Dual' as dual_status,
		date_trunc(month, to_date(REPORT_RUN_DATE, 'YYYYMMDD')) as report_date,
		'hmo_tucson' as lob_file,
		'Tucson MA' as source_lob,
	from SOURCE_PROD.united.src_united_enrollment_hmo_tucson ue
		
	union all

	select
		CES_ALT_ID as member_id,
		to_varchar(MBI) as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Tucson' as payer_contract,
		lower(F_NAME) as first_name,
		lower(L_NAME) as last_name,
		null as middle_name,
		lower(M_INIT) as middle_initial,
		to_date(DOB, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '') = '' then null
        when length(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')) = 11
            and left(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', ''), 10)
        when length(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')) = 10
            then regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')
        else null
    end
 as phone,
		null as language_preference,
		lower(GENDER) as gender,
		lower(ADDR1) as address_line_1,
		lower(ADDR2) as address_line_2,
		lower(ue.CITY) as city,
		lower(ue.STATE) as state,
		to_varchar(ZIP) as zip,
		to_date(ORIG_EFF, 'MM/DD/YYYY') as original_effective_date,
		to_date(ENR_EFF, 'MM/DD/YYYY') as enrollment_effective_date, -- suvida start date
		to_varchar(NPI_NBR) as pcp_npi,
		lower(trim(replace(PROVNAME, split_part(PROVNAME, ' ', -1), ''))) as provider_last_name,
		lower(split_part(PROVNAME, ' ', -1)) as provider_first_name,
		PRV_TIN as pcp_tin,
		src_file_name,
		ue.CONTRACT || '-' || LPAD(ue.PBP, 3, '0') || '-' || coalesce(ue.SEGMENT_ID, '000') as plan_code,
		MKP_DESCRIPTION as plan_name,
		0 as plan_name_match,
		'Non-Dual' as dual_status,
		date_trunc(month, to_date(CR_DATE, 'MM/DD/YYYY')) as report_date,
		'ppo_tucson' as lob_file,
		'Tucson MA' as source_lob,
	from SOURCE_PROD.united.src_united_enrollment_ppo_tucson ue

	union all

	select
		CES_ALT_ID as member_id,
		to_varchar(MBI) as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		'United AZ Phoenix' as payer_contract,
		lower(F_NAME) as first_name,
		lower(L_NAME) as last_name,
		null as middle_name,
		lower(M_INIT) as middle_initial,
		to_date(DOB, 'MM/DD/YYYY') as birth_date,
		
    
    case
        when regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '') = '' then null
        when length(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')) = 11
            and left(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', ''), 10)
        when length(regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')) = 10
            then regexp_replace(to_varchar(HAREA_CD) || to_varchar(HPHONE), '[^0-9]', '')
        else null
    end
 as phone,
		null as language_preference,
		lower(GENDER) as gender,
		lower(ADDR1) as address_line_1,
		lower(ADDR2) as address_line_2,
		lower(ue.CITY) as city,
		lower(ue.STATE) as state,
		to_varchar(ZIP) as zip,
		to_date(ORIG_EFF, 'MM/DD/YYYY') as original_effective_date,
		to_date(ENR_EFF, 'MM/DD/YYYY') as enrollment_effective_date, -- suvida start date
		to_varchar(NPI_NBR) as pcp_npi,
		lower(trim(replace(PROVNAME, split_part(PROVNAME, ' ', -1), ''))) as provider_last_name,
		lower(split_part(PROVNAME, ' ', -1)) as provider_first_name,
		PRV_TIN as pcp_tin,
		src_file_name,
		ue.CONTRACT || '-' || LPAD(ue.PBP, 3, '0') || '-' || coalesce(ue.SEGMENT_ID, '000') as plan_code,
		MKP_DESCRIPTION as plan_name,
		0 as plan_name_match,
		'Non-Dual' as dual_status,
		date_trunc(month, to_date(CR_DATE, 'MM/DD/YYYY')) as report_date,
		'ppo_phoenix' as lob_file,
		'Phoenix MA' as source_lob,
	from SOURCE_PROD.united.src_united_enrollment_ppo_phoenix ue

	union all

	select
		data:"CES_ALT_ID"::string as member_id,
		data:"MBI"::string as medicare_beneficiary_id,
		null as gmpi_id,
		'United' as source,
		'United' as payer_parent,
		'United AZ' as payer_name,
		case
			when _ab_source_file_url ilike '%phoenix%' then 'United AZ Phoenix'
			when _ab_source_file_url ilike '%tucson%' then 'United AZ Tucson'
		end as payer_contract,
		lower(data:"F_NAME"::string) as first_name,
		lower(data:"L_NAME"::string) as last_name,
		null as middle_name,
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
		null as language_preference,
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
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar as src_file_name,
		data:"CONTRACT"::string || '-' || lpad(data:"PBP"::string, 3, '0') || '-' || coalesce(data:"SEGMENT_ID"::string, '000') as plan_code,
		data:"MKP_DESCRIPTION"::string as plan_name,
		0 as plan_name_match,
		'Non-Dual' as dual_status,
		coalesce(
			try_to_date(regexp_substr(_ab_source_file_url, '\\d{8}'), 'MMDDYYYY'),
			date_trunc(month, to_date(data:"CR_DATE"::string, 'MM/DD/YYYY'))
		) as report_date,
		case
			when split(data:"MKP_DESCRIPTION"::string, ' ')[1]::varchar ilike '%ppo%' then 'ppo'
			else 'hmo'
		end || '_' ||
		case
			when _ab_source_file_url ilike '%phoenix%' then 'phoenix'
			when _ab_source_file_url ilike '%tucson%' then 'tucson'
		end as lob_file,
		case
			when _ab_source_file_url ilike '%phoenix%' then 'Phoenix MA'
			when _ab_source_file_url ilike '%tucson%' then 'Tucson MA'
		end as source_lob,
	from airbyte_source_prod.united_az.assignment_cosmos
)
select
	*,
	null as agent_number,
	null as agent_info,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	enrollment_effective_date as suvida_start_date,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from united_enrollment_data
  );

