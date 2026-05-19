
  create or replace   view dw_dev.dev_jkizer_staging.stg_medical_claim
  
  copy grants
  
  
  as (
    with suvida_npi as (
	select 
		distinct npi
	from dw_dev.dev_jkizer.dim_provider
)
select
	medical_claim_id,
	claim_id,
	claim_line_number,
	encounter_id,
	encounter_type,
	encounter_group,
	claim_type,
	person_id as suvida_id,
	member_id,
	payer,
	plan,
	claim_start_date,
	claim_end_date,
	claim_line_start_date,
	claim_line_end_date,
	admission_date,
	discharge_date,
	service_category_1,
	service_category_2,
	service_category_3,
	admit_source_code,
	admit_source_description,
	admit_type_code,
	admit_type_description,
	discharge_disposition_code,
	discharge_disposition_description,
	place_of_service_code,
	place_of_service_description,
	bill_type_code,
	bill_type_description,
	drg_code_type,
	drg_code,
	drg_description,
	revenue_center_code,
	revenue_center_description,
	service_unit_quantity,
	hcpcs_code,
	hcpcs_modifier_1,
	hcpcs_modifier_2,
	hcpcs_modifier_3,
	hcpcs_modifier_4,
	hcpcs_modifier_5,
	rendering_id,
	rendering_tin,
	rendering_name,
	billing_id,
	billing_tin,
	billing_name,
	facility_id,
	facility_name,
	paid_date,
	paid_amount,
	allowed_amount,
	charge_amount,
	coinsurance_amount,
	copayment_amount,
	deductible_amount,
	total_cost_amount,
	in_network_flag,
	enrollment_flag,
	member_month_key,
	data_source,
	tuva_last_run,
	iff(datediff(month, date_trunc(month, claim_start_date), current_date) > 3, true, false) as is_claim_within_last_3_months,
	iff(
		rendering_tin in ('882864363', '884143824', '932299398') 
		or billing_tin in ('882864363', '884143824', '932299398')
		or sn.npi is not null
		or sn2.npi is not null
	, true, false) as suvida_claim_flag,
from suvida_tuva.core.medical_claim mc
left join suvida_npi sn 
	on mc.rendering_id = sn.npi
left join suvida_npi sn2 
	on mc.billing_id = sn2.npi
where data_source in ('Devoted','Wellcare/Centene','UHG/Wellmed','United') 
and date_trunc(month, claim_start_date) in ('2023-01-01','2023-02-01','2023-03-01','2023-04-01','2023-05-01','2023-06-01','2023-07-01','2023-08-01','2023-09-01','2023-10-01','2023-11-01','2023-12-01','2024-01-01','2024-02-01','2024-03-01','2024-04-01','2024-05-01','2024-06-01','2024-07-01','2024-08-01','2024-09-01','2024-10-01','2024-11-01','2024-12-01', '2025-01-01','2025-02-01','2025-03-01','2025-04-01','2025-05-01','2025-06-01','2025-07-01','2025-08-01','2025-09-01','2025-10-01','2025-11-01','2025-12-01','2026-01-01','2026-02-01')
and date_trunc(month, claim_start_date) <= dateadd(month, -3, current_date())
and (
	data_source != 'Devoted'
	or (
		data_source = 'Devoted'
		and (claim_type = 'institutional' or (claim_type = 'professional' and place_of_service_code != 99)) -- remove supplemental benefits
		and (claim_type = 'institutional' or (claim_type = 'professional' and place_of_service_code is not null)) -- remove supplemental benefits
	)
)
  );

