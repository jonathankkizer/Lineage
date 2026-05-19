

with max_intmdt_assignment_idx as (
	select 
		siw.suvida_id,
		dmp.report_date
	from dw_dev.dev_jkizer.dim_assignment_patient dmp
	inner join dw_dev.dev_jkizer.suvida_id_walk siw 
		on dmp.member_id = siw.member_id
		and dmp.source = siw.source
	qualify dense_rank() over (partition by siw.suvida_id order by report_date asc) = 1 -- grab earliest patient info
)

select distinct
	miep_idx.suvida_id,
	ps.address_line_1,
	case
		when ps.address_line_2 is not null and ps.address_line_2 <> 'n/a' then ps.address_line_2
		else null
	end as address_line_2,
	ps.city,
	ps.state,
	ps.zip
from max_intmdt_assignment_idx miep_idx 
left join dw_dev.dev_jkizer.patient_summary ps
	on miep_idx.suvida_id = ps.suvida_id
left join dw_dev.dev_jkizer_staging.patient_addresses pa 
	on ps.suvida_id = pa.suvida_id and
	   lower(coalesce(ps.address_line_1, '')) = lower(pa.address_line_1_key) and
	   lower(coalesce(ps.address_line_2, '')) = lower(pa.address_line_2_key) and
	   lower(coalesce(ps.city, '')) = lower(pa.city_key) and
	   lower(coalesce(ps.state, '')) = lower(pa.state_key) and
	   lower(coalesce(ps.zip, '')) = lower(pa.zip_key) and	   
	   pa.source = 'Google'
where
	miep_idx.report_date between dateadd(day, -7, current_date()) and current_date() 
	and ps.address_line_1 is not null 
	and pa.suvida_id is null

union all

select
	ps.suvida_id,
	ps.address_line_1,
	coalesce(ps.address_line_2, '') as address_line_2,
	coalesce(ps.city, '') as city,
	coalesce(ps.state, '') as state,
	coalesce(ps.zip, '') as zip
from dw_dev.dev_jkizer.patient_summary ps
left join dw_dev.dev_jkizer_staging.patient_addresses pa
	on ps.suvida_id = pa.suvida_id and
	   lower(coalesce(ps.address_line_1, '')) = lower(pa.address_line_1_key) and
	   lower(coalesce(ps.address_line_2, '')) = lower(pa.address_line_2_key) and
	   lower(coalesce(ps.city, '')) = lower(pa.city_key) and
	   lower(coalesce(ps.state, '')) = lower(pa.state_key) and
	   lower(coalesce(ps.zip, '')) = lower(pa.zip_key) and	   
	   pa.source = 'Google'
where
	(is_active_assignment = 1 or is_future_assignment = 1) and
    pa.address_id is null and
	coalesce(ps.address_line_1, '') <> '' and
	(
		coalesce(ps.city, '') <> '' or
		(
			coalesce(ps.state, '') <> '' and
			coalesce(ps.zip, '') <> ''
		)
	)