with payer_assignment as (
	select 
		suvida_id,
		fam.assignment_month,
		dmpr.suvida_roster_provider_name as provider_name,
		dmpr.suvida_roster_npi as provider_npi,
		dp.location_name,
	from dw_dev.dev_jkizer.fct_assignment_month fam 
	inner join dw_dev.dev_jkizer.dim_assignment_patient dmp 
		using (member_file_skey)
	inner join dw_dev.dev_jkizer.dim_assignment_provider dmpr
		using (provider_file_skey)
	left join dw_dev.dev_jkizer.dim_provider dp 
		on dmpr.suvida_roster_npi = dp.npi
	qualify row_number() over (partition by suvida_id, assignment_month order by fam.source desc) = 1 -- FIX THIS!!! (e.g., how should we tie break payers for the same month?)
), suvida_assignment as (
	select
		fppa.suvida_id,
		fppa.report_month,
		dp.provider_name,
		fppa.assigned_npi as provider_npi,
		fpla.location_name,
	from dw_dev.dev_jkizer.fct_patient_provider_assignment fppa
	left join dw_dev.dev_jkizer.dim_provider dp 
		on fppa.assigned_npi = dp.npi
	left join dw_dev.dev_jkizer.fct_patient_location_assignment fpla 
		on fppa.suvida_id = fpla.suvida_id
		and fppa.report_month = fpla.report_month
		and fpla.current_location_assignment = true
	where fppa.current_provider_assignment = true
)
select
	coalesce(sa.suvida_id, pa.suvida_id) as suvida_id,
	coalesce(sa.report_month, pa.assignment_month) as care_assignment_month,
	coalesce(sa.provider_name, pa.provider_name) as provider_name,
	coalesce(sa.provider_npi, pa.provider_npi) as provider_npi,
	coalesce(sa.location_name, pa.location_name) as location_name,
from suvida_assignment sa 
full outer join payer_assignment pa 
	on sa.suvida_id = pa.suvida_id
	and sa.report_month = pa.assignment_month
group by all