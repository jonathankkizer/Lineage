-- *************************************************
-- This dbt model creates the condition table in core.
-- *************************************************



with unpivot_cte as (
	select
		d.data_source,
		d.claim_id,
		d.claim_line_number,
		d.diagnosis_position,
		d.icd_10_code,
		c.hcpcs_code,
		c.hcpcs_modifier_1,
		c.claim_type,
		c.service_category_1,
		c.bill_type_code,
		c.claim_start_date as diagnosis_date,
		c.member_id,
	from dw_dev.dev_jkizer_staging.stg_claims_expanded_diagnosis d
	left join dw_dev.dev_jkizer_staging.stg_medical_claim c
		on d.data_source = c.data_source
		and d.claim_id = c.claim_id
		and d.claim_line_number = c.claim_line_number
), med_claim_data as (
	select
		data_source,
		claim_id,
		claim_line_number,
		claim_type,
		bill_type_code,
		place_of_service_code,
		hcpcs_code,
		claim_start_date,
	from dw_dev.dev_jkizer_staging.stg_medical_claim
), risk_adj_status as (
	select 
		data_source,
		claim_id,
		claim_line_number, -- logic for following taken from Tuva implementation of CMS HCC model
		max(
			case when claim_type = 'professional' and cpt.hcpcs_cpt_code is not null then true
			else false
			end
		) as is_professional_risk_adjustable,
		max(
			case when claim_type = 'institutional' and substring(bill_type_code, 1, 2) in ('11','41') then true
			else false
			end
		) as is_inpatient_risk_adjustable,
		max(
			case when claim_type = 'institutional' and substring(bill_type_code, 1, 2) in ('12','13','43','71','73','76','77','85')
			then true
			else false
			end
		) as is_outpatient_bill_type_code_check,
		max(iff(mc.place_of_service_code = '21', true, false)) as is_inpatient_diagnosis,
	from med_claim_data mc
	left join dw_dev.dev_jkizer_staging.stg_ref_hcc_risk_adjustable_cpt cpt
		on mc.hcpcs_code = cpt.hcpcs_cpt_code
		and cpt.year = year(mc.claim_start_date)
	group by all
), outpatient_procedure_risk_adjustable as (
	select
		mc.data_source,
		mc.claim_id,
		max(iff(cpt.hcpcs_cpt_code is not null, true, false)) as is_outpatient_risk_adjustable
	from med_claim_data mc
	inner join risk_adj_status ras
		on mc.claim_id = ras.claim_id
		and mc.claim_line_number = ras.claim_line_number
	left join dw_dev.dev_jkizer_staging.stg_ref_hcc_risk_adjustable_cpt cpt
		on mc.hcpcs_code = cpt.hcpcs_cpt_code
		and cpt.year = year(mc.claim_start_date)
	where is_outpatient_bill_type_code_check = true
	group by all
), 

final as (
	select
	md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.claim_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.claim_line_number as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.diagnosis_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.hcpcs_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.diagnosis_position as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(unpivot_cte.data_source as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as claims_diagnosis_skey,
	siw.suvida_id,
	unpivot_cte.claim_id,
	unpivot_cte.claim_line_number,
	unpivot_cte.member_id,
	unpivot_cte.hcpcs_code,
	unpivot_cte.hcpcs_modifier_1,
	unpivot_cte.diagnosis_date,
	unpivot_cte.icd_10_code,
	unpivot_cte.diagnosis_position,
	unpivot_cte.data_source as data_source,
	greatest_ignore_nulls(is_professional_risk_adjustable, is_inpatient_risk_adjustable, is_outpatient_risk_adjustable) as is_risk_adjustable,
	ras.is_inpatient_diagnosis
	from unpivot_cte
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on unpivot_cte.member_id = siw.member_id
		and unpivot_cte.data_source = siw.source
	left join risk_adj_status ras
		on unpivot_cte.data_source = ras.data_source
		and unpivot_cte.claim_id = ras.claim_id
		and unpivot_cte.claim_line_number = ras.claim_line_number
	left join outpatient_procedure_risk_adjustable oras
		on unpivot_cte.data_source = oras.data_source
		and unpivot_cte.claim_id = oras.claim_id
	group by all 
)

select final.* from final  

  

left join (select claims_diagnosis_skey from dw_dev.dev_jkizer.fct_claims_diagnosis) as unique_keys on unique_keys.claims_diagnosis_skey = final.claims_diagnosis_skey
where unique_keys.claims_diagnosis_skey is null

