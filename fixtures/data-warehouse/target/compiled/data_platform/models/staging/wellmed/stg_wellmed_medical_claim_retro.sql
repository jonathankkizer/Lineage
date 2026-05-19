with data as (
	select
		to_varchar(c.data:claim_number::varchar) as claim_id,
		c.data:original_claim_number::varchar as original_claim_id,
		c.data:line_number::varchar as claim_line_number,
		case
			when c.data:claim_type::varchar = 'INST' then 'INSTITUTIONAL'
			when c.data:claim_type::varchar = 'PROF' then 'PROFESSIONAL'
		end as claim_type,
		c.data:subscriber_mbi::varchar as patient_id,
		case
			when right(c.data:subscriber_id::varchar, 3) != '01'
			then concat(c.data:subscriber_id::varchar, '-01')
			else c.data:subscriber_id::varchar
		end as member_id,
		try_to_date(nullif(nullif(c.data:statement_from::varchar, ''), 'NULL'), 'YYYYMMDD') as claim_start_date,
		try_to_date(nullif(nullif(c.data:statement_to::varchar, ''), 'NULL'), 'YYYYMMDD') as claim_end_date,
		try_to_date(nullif(nullif(c.data:date_service_from::varchar, ''), 'NULL'), 'YYYYMMDD') as claim_line_start_date,
		try_to_date(nullif(nullif(c.data:date_service_to::varchar, ''), 'NULL'), 'YYYYMMDD') as claim_line_end_date,
		try_to_date(nullif(nullif(c.data:admit_date::varchar, ''), 'NULL'), 'YYYYMMDD') as admission_date,
		try_to_date(nullif(nullif(c.data:discharge_date::varchar, ''), 'NULL'), 'YYYYMMDD') as discharge_date,
		nullif(c.data:admission_source::varchar, '') as admit_source_code,
		nullif(c.data:admit_type::varchar, '') as admit_type_code,
		nullif(c.data:discharge_status::varchar, '') as discharge_disposition_code,
		c.data:place_of_service::varchar as place_of_service_code,
		nullif(to_varchar(c.data:bill_type::varchar), '') as bill_type_code,
		nullif(c.data:ms_drg::varchar, '') as ms_drg_code,
		to_varchar(null) as apr_drg_code,
		nullif(to_varchar(c.data:revenue_code::varchar), '') as revenue_center_code,
		try_to_double(nullif(c.data:units::varchar, '')) as service_unit_quantity,
		c.data:procedure_code::varchar as hcpcs_code,
		nullif(c.data:modifier_codes::varchar, '') as hcpcs_modifier_codes,
		replace(c.data:dx_codes::varchar, '.', '') as dx_codes,
		c.data:rendering_provider_npi::varchar as rendering_npi,
		c.data:vendor_npi::varchar as billing_npi,
		c.data:vendor_npi::varchar as facility_npi,
		try_to_date(nullif(nullif(c.data:paid_date::varchar, ''), 'NULL'), 'YYYYMMDD') as paid_date,
		try_to_double(nullif(c.data:line_paid::varchar, '')) as paid_amount,
		try_to_double(nullif(c.data:line_allowed::varchar, '')) as allowed_amount,
		try_to_double(nullif(c.data:billed_amount::varchar, '')) as charge_amount,
		try_to_double(nullif(c.data:billed_amount::varchar, '')) as total_cost_amount,
		'UHG/Wellmed' as data_source,
		split(c._ab_source_file_url, '/')[array_size(split(c._ab_source_file_url, '/'))-1]::varchar as src_file_name,
		coalesce(
			try_to_date(nullif(nullif(c.data:health_plan_report_date::varchar, ''), 'NULL')),
			case
				when split(c._ab_source_file_url, '/')[array_size(split(c._ab_source_file_url, '/'))-1]::varchar like '%runout%'
				then try_to_date(regexp_substr(split(c._ab_source_file_url, '/')[array_size(split(c._ab_source_file_url, '/'))-1]::varchar, '\\d{8}', 1, 2), 'YYYYMMDD')
				else try_to_date(regexp_substr(split(c._ab_source_file_url, '/')[array_size(split(c._ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 'YYYYMMDD')
			end
		) as last_update,
		dense_rank() over (partition by member_id, year(claim_line_start_date) order by last_update desc) as _rn,
		1 as report_priority,
		to_varchar(c.data:vendor_tin::varchar) as rendering_tin,
	from airbyte_source_prod.wellmed.claims_retro c
	where c.data:claim_number::varchar is not null
	and nullif(nullif(c.data:paid_date::varchar, ''), 'NULL') is not null
)
select *, 
	row_number() over (partition by claim_id, claim_line_number, dx_codes order by last_update desc) as claim_id_rn
from data