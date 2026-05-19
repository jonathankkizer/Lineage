with prov_incentives as (
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_a1c_control

	union all
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_note_closure

	union all
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_awv

	union all
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_hbp_control

	union all 
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_chf_screening

	union all 
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_pvd_screening

	union all 
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_med_adherence

	union all 
	select 
		measure_year,
		suvida_id,
		elation_id,
		first_name,
		last_name,
		birth_date,
		location_name,
		provider_name,
		next_pcp_appt_date,
		measure_group,
		measure_name,
		measure_detail,
		measure_numerator,
		measure_denominator
	from dw_dev.dev_jkizer.prov_incentive_redocumentation

),

pcp_visits as (
	select
		year(encounter_date) as measure_year,
		suvida_id,
		count(distinct case when is_pcp = 1 then encounter_date else null end) as num_pcp_visits_ytd,
	from dw_dev.dev_jkizer.fct_procedure
	group by 1,2
)

select 
	sysdate() as created_at_datetime,
	md5(cast(coalesce(cast(prov.measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(prov.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_group as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_detail as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as prov_incentive_id,
	prov.*,
	case
		when pcp_visits.num_pcp_visits_ytd is null or pcp_visits.num_pcp_visits_ytd = 0 then '0 visits'
		when pcp_visits.num_pcp_visits_ytd = 1 then '1 visits'
		when pcp_visits.num_pcp_visits_ytd between 2 and 4 then '2-4 visits'
		else '4+ visits'
	end as num_pcp_visits_ytd_group
from prov_incentives prov
left join pcp_visits on pcp_visits.suvida_id = prov.suvida_id and pcp_visits.measure_year = prov.measure_year