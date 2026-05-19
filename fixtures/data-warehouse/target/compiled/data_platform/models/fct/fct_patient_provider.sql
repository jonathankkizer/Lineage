with provider_data as ( -- combine elation-listed provider information w/ dim_provider to pull in latest assigned and primary provider information
	select
		siw.suvida_id,
		ep.elation_id,
		ep.source,
		ep.primary_physician_user_id,
		ep.primary_care_provider_user_id,
		dp1.provider_name as assigned_provider_name,
		dp2.provider_name as primary_provider_name,
		nullif(dp1.npi, '.') as assigned_provider_npi,
		nullif(dp2.npi, '.') as primary_provider_npi,
		coalesce(nullif(dp1.provider_name, 'Unassigned'), nullif(dp2.provider_name, 'Unassigned')) as provider_name,
		coalesce(nullif(dp1.npi, '.'), nullif(dp2.npi, '.')) as provider_npi,
		coalesce(dp1.location_name, dp2.location_name) as provider_location_name,
		coalesce(dp1.location_state, dp2.location_state) as provider_location_state, 
		coalesce(dp1.market_name, dp2.market_name) as provider_location_market,
		row_number() over (partition by siw.suvida_id order by ep.last_modified_datetime desc) as _idx
	from dw_dev.dev_jkizer_staging.stg_elation_patient ep 
	left join dw_dev.dev_jkizer.suvida_id_walk siw 
		on ep.source = siw.source 
		and ep.elation_id = siw.member_id
	left join dw_dev.dev_jkizer.dim_provider dp1
		on ep.primary_physician_user_id = dp1.user_id
	left join dw_dev.dev_jkizer.dim_provider dp2
		on ep.primary_care_provider_user_id = dp2.canonical_physician_id
)
select 
	suvida_id,
	elation_id,
	source,
	primary_physician_user_id,
	primary_care_provider_user_id,
	assigned_provider_name,
	primary_provider_name,
	assigned_provider_npi,
	primary_provider_npi,
	provider_name,
	provider_npi,
	provider_location_name,
	provider_location_state, 
	provider_location_market
from provider_data
where _idx = 1