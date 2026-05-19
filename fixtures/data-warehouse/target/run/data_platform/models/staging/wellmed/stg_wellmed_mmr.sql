
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellmed_mmr
  
  copy grants
  
  
  as (
    select
	iff(right(data:subscriber_id::varchar, 3) != '-01', concat(data:subscriber_id::varchar, '-01'), data:subscriber_id::varchar) as subscriber_id,
	data:gmpi_id::varchar as gmpi_id,
	data:Subscriber_MBI::varchar as medicare_beneficiary_id,
	data:Code_Payor::varchar as code_payor,
	try_to_date(nullif(nullif(concat(data:Cap_Period::varchar, '01'), '01'), 'NULL01'), 'YYYYMMDD') as period_month,
	try_to_date(nullif(nullif(concat(data:Cap_Period::varchar, '01'), '01'), 'NULL01'), 'YYYYMMDD') as cap_period_month,
	try_to_date(nullif(nullif(concat(data:Cap_Process_Month::varchar, '01'), '01'), 'NULL01'), 'YYYYMMDD') as process_month,
	try_to_date(nullif(nullif(concat(data:Cap_Process_Month::varchar, '01'), '01'), 'NULL01'), 'YYYYMMDD') as cap_process_month,
	0 as original_reason_entitlement_code,
	data:current_retro_indicator::varchar as current_retro_indicator,
	data:CMS_Contract_ID::varchar as cms_contract_id,
	data:PBP_ID::varchar as pbp_id,
	data:Record_Type::varchar as record_type,
	data:Adj_Code::varchar as adj_code,
	try_to_double(nullif(nullif(data:capped_count::varchar, ''), 'NULL')) as capped_count,
	try_to_double(nullif(nullif(data:transaction_count::varchar, ''), 'NULL')) as transaction_count,
	data:CAP_ENTITLED_INDICATOR::varchar as cap_entitled_indicator,
	data:TRANSACTION_CAUSE::varchar as transaction_cause,
	try_to_double(nullif(nullif(data:net_payment_amt::varchar, ''), 'NULL')) as net_payment_amount,
	data:RA_FACTOR_TYPE_CODE::varchar as raf_type_code,
	data:RAF_Type_Description::varchar as raf_type_description,
	try_to_double(nullif(nullif(data:raf_score::varchar, ''), 'NULL')) as raf_score,
	split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
	try_to_date(substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, 25, 8), 'YYYYMMDD') as src_file_date,
	'UHG/Wellmed' as source,
	dense_rank() over (partition by year(try_to_date(nullif(nullif(concat(data:Cap_Period::varchar, '01'), '01'), 'NULL01'), 'YYYYMMDD')), try_to_date(nullif(nullif(concat(data:Cap_Period::varchar, '01'), '01'), 'NULL01'), 'YYYYMMDD') order by try_to_date(substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, 25, 8), 'YYYYMMDD') desc) as mmr_process_month_report_rank,
from airbyte_source_prod.wellmed.mmr
  );

