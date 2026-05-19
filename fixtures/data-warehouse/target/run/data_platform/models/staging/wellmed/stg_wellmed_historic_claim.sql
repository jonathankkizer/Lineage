
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellmed_historic_claim
  
  copy grants
  
  
  as (
    /* -- unused logic to expand out hcpcs and dx_codes for Snowflake, convert to split_to_table
with hcpcs_mods as (
    select 
      claim_number, 
      original_claim_number, 
      health_plan_report_date, 
      src_file_name, b.*
    from source_prod.wellmed.src_wellmed_historic_claims
    cross apply string_split(modifier_codes, ',', 1) b
), dx_codes as (
    select 
      claim_number, 
      original_claim_number, 
      health_plan_report_date, 
      src_file_name, 
      b.*
    from source_prod.wellmed.src_wellmed_historic_claims
    cross apply string_split(dx_codes, ',', 1) b
)
*/
select
  c.claim_number as claim_id,
  c.original_claim_number as original_claim_id,
  c.line_number as claim_line_number,
  case 
    when claim_type = 'INST' then 'INSTITUTIONAL'
    when claim_type = 'PROF' then 'PROFESSIONAL'
  end as claim_type,
  subscriber_mbi as patient_id,
  case 
    when right(subscriber_id, 3) != '01' 
    then concat(subscriber_id, '-01') 
    else subscriber_id
  end as member_id,
  date(statement_from, 'YYYYMMDD') as claim_start_date,
  date(statement_to, 'YYYYMMDD') as claim_end_date,
  date(date_service_from, 'YYYYMMDD') as claim_line_start_date,
  date(date_service_to, 'YYYYMMDD') as claim_line_end_date,
  date(admit_date, 'YYYYMMDD') as admission_date,
  date(discharge_date, 'YYYYMMDD') as discharge_date,
  admission_source as admit_source_code,
  admit_type as admit_type_code,
  discharge_status as discharge_disposition_code,
  place_of_service as place_of_service_code,
  bill_type as bill_type_code,
  ms_drg as ms_drg_code,
  to_varchar(null) as apr_drg_code,
  revenue_code as revenue_center_code,
  units as service_unit_quantity,
  procedure_code as hcpcs_code,
  modifier_codes as hcpcs_modifier_codes,
  replace(dx_codes, '.', '') as dx_codes,
  nullif(rendering_provider_npi, 'NULL') as rendering_npi,
  nullif(vendor_npi, 'NULL') as billing_npi,
  nullif(vendor_npi, 'NULL') as facility_npi,
  date(PAID_DATE, 'YYYYMMDD') as paid_date,
  try_to_number(line_paid, 38, 8) as paid_amount,
  try_to_number(line_allowed, 38, 8) as allowed_amount,
  try_to_number(billed_amount, 38, 8) as charge_amount,
  try_to_number(billed_amount, 38, 8) as total_cost_amount,
  'UHG/Wellmed' as data_source,
  c.src_file_name,
  date(c.health_plan_report_date) as last_update,
  row_number() over (partition by claim_number, line_number order by date(c.health_plan_report_date) desc) as _rn,
  2 as report_priority,
from source_prod.wellmed.src_wellmed_historic_claims c
where c.claim_number is not null
and paid_date != 'NULL'
  );

