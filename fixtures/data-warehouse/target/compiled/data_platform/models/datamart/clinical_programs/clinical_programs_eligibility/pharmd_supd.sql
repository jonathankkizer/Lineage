with time_period as (
	select
		date_month as date_month_start,
		last_day(date_month) as date_month_end,
	from dw_dev.dev_jkizer.dim_date
	where is_bom = true
	and date_day >= dateadd(month, -18, current_date()) -- carry the last 18 months rolling
	and date_day <= current_date() -- do not bring in future dates
)
select
	tp.date_month_start,
	tp.date_month_end,
	fqm.suvida_id,
	listagg(distinct fqm.measure_source || ' | ' || cast(fqm.report_date as string), ' || ') as eligibility_evidence,
	'pharmd' as team,
	'supd' as program,
	'pharmd_supd' as eligibility_logic
from time_period tp
inner join dw_dev.dev_jkizer.fct_quality_measure fqm
	on 1=1
where fqm.quality_measure = 'Statin Use in Persons with Diabetes'
and year(date_month_start) = year(fqm.measure_year)
and fqm.quality_report_in_month_rank = 1
and fqm.measure_numerator = 0
and date_trunc(month, fqm.report_date) = date_month_start
group by tp.date_month_start, tp.date_month_end, fqm.suvida_id