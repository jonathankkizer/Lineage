
  
    

create or replace transient table dw_dev.dev_jkizer.int_churn_management
    copy grants
    
    
    as (select
	pa.date_month,
	pa.suvida_id,
	ps.elation_id,
	ps.elation_patient_url,
	ps.full_name,
	ps.birth_date,
	ps.phone,
	ps.address_line_1,
	ps.address_line_2,
	ps.city,
	ps.state,
	ps.zip,
	pa.prev_month_assignment_payer_name as previous_payer_name,
	ps.market_name,
	ps.location_name,
	ps.provider_name,
	pa.patient_assignment_skey,
	md5(cast(coalesce(cast(pa.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pa.date_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.full_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.birth_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.address_line_1 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.city as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.state as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.zip as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pa.prev_month_assignment_payer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.market_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_churn_info_skey,
from dw_dev.dev_jkizer.patient_assignment pa
inner join dw_dev.dev_jkizer.patient_summary ps 
	on pa.suvida_id = ps.suvida_id
	and ps.is_active_assignment = 0 -- currently unassigned; patient hasn't come back
where assignment_bucket = 'lost'
and date_month >= dateadd(month, -3, current_date())
and current_date() >= dateadd(day, 15, date_trunc(month, date_month)) -- only add patients once we're 15+ days into the month, to give time for assignment data to catch up
    )
;


  