with all_data as (
	select
		iep.provider_file_skey,
		iep.provider_first_name,
		iep.provider_last_name,
		iep.pcp_npi,
		dim.market_name,
		dim.location_state,
		iep.payer_provider_id,
		iep.source,
		iep.report_date,
		iep.src_file_name,
		iep.report_index,
		coalesce(dim.provider_name, concat(iep.provider_first_name, ' ', iep.provider_last_name)) as suvida_roster_provider_name,
		coalesce(dim.npi, iep.pcp_npi) as suvida_roster_npi,
		iff(dim.npi is null, 0, 1) as is_suvida_roster_provider,
	from dw_dev.dev_jkizer.intmdt_assignment iep
	left join dw_dev.dev_jkizer.dim_provider dim 
		on iep.pcp_npi = dim.npi
)
select 
	ad.*
from all_data ad