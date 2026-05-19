
  create or replace   view dw_dev.dev_jkizer_staging.stg_cms_cpsc_contract_info
  
  copy grants
  
  
  as (
    select
	"CONTRACT ID" as contract_id,
	"PLAN ID" as plan_id,
	contract_id || plan_id as contract_plan_id,
	"PARENT ORGANIZATION" as parent_organization,
	"ORGANIZATION MARKETING NAME" as organization_marketing_name,
	"ORGANIZATION NAME" as organization_name,
	"ORGANIZATION TYPE" as organization_type,
	"PLAN NAME" as plan_name,
	"PLAN TYPE" as plan_type,
	"SNP PLAN" as snp_plan,
	"OFFERS PART D" as offers_part_d,
	to_date("CONTRACT EFFECTIVE DATE", 'MM/DD/YYYY') as contract_effective_date,
	split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
	to_date(split(replace(src_file_name, '.csv', ''), '_')[3]||split(replace(src_file_name, '.csv', ''), '_')[4]||'01', 'YYYYMMDD') as src_file_date,
	dense_rank() over (partition by year(src_file_date) order by src_file_date desc) as year_file_rank,
	row_number() over (partition by contract_plan_id order by src_file_date desc) as contract_plan_id_rank,
from airbyte_source_prod.cms.cpsc_contract_info
  );

