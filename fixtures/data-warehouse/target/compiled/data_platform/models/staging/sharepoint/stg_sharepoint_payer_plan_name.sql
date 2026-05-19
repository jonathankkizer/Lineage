select
	plan_code,
	plan_name as plan_name,
	plan_group,
	elation_plan_name as emr_plan_name,
	elation_carrier_id as emr_carrier_id,
	elation_plan_id as emr_plan_id,
	payer_name as payer_name,
	address,
	city,
	state,
	zip_code,
	plan_year,
	source,
	row_number() over (partition by plan_code, payer_name order by plan_year desc, plan_name asc) as _rn
from source_prod.sharepoint.src_sharepoint_payer_plan_names