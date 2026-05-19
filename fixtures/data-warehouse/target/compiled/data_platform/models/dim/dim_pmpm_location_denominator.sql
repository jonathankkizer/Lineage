-- breaking best practices here to force PMPM denominator work for Finance 

with data as (
	select 
		pca.location_name, 
		financial_source, 
		count(distinct(financial_membership_skey)) as denominator,
		sum(revenue) as revenue,
		sum(projection_adjusted_revenue) as projection_adjusted_revenue,
	from dw_dev.dev_jkizer.patient_financial_membership fm
	inner join dw_dev.dev_jkizer.patient_care_assignment pca 
		on pca.suvida_id =  fm.suvida_id
		and pca.care_assignment_month = fm.financial_member_month
	left join dw_dev.dev_jkizer.patient_revenue pr
		on fm.suvida_id = pr.suvida_id
		and fm.financial_member_month = pr.mmr_month
	where financial_member_month_ind = 1
	and fm.financial_member_month between dateadd(month, -15, date_trunc(month, current_date())) and dateadd(month, -3, date_trunc(month, current_date()))
	group by all
)

select 
	*, 
	sum(denominator) over (partition by location_name) as static_location_denominator,
	sum(revenue) over (partition by location_name) as static_location_revenue,
	sum(projection_adjusted_revenue) over (partition by location_name) as static_location_proj_revenue,
	sum(denominator) over (partition by location_name, financial_source) as static_location_financial_source_denominator,
	sum(revenue) over (partition by location_name, financial_source) as static_location_financial_source_revenue,
	sum(projection_adjusted_revenue) over (partition by location_name, financial_source) as static_location_financial_source_proj_revenue,
	sum(denominator) over (partition by financial_source) as static_financial_source_denominator, 
	sum(revenue) over (partition by financial_source) as static_financial_source_revenue,
	sum(projection_adjusted_revenue) over (partition by financial_source) as static_financial_source_proj_revenue,
from data