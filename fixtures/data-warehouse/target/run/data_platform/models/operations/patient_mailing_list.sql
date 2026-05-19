
  create or replace   view dw_dev.dev_jkizer.patient_mailing_list
  
  copy grants
  
  
  as (
    

with max_intmdt_assignment_idx as (
    select 
        siw.suvida_id,
        dmp.report_date
    from dw_dev.dev_jkizer.dim_assignment_patient dmp
    inner join dw_dev.dev_jkizer.suvida_id_walk siw 
        on dmp.member_id = siw.member_id
        and dmp.source = siw.source
    qualify dense_rank() over (partition by siw.suvida_id order by report_date asc) = 1 -- grab earliest patient info
), patient_service_location_distances as (
	select
		suvida_id,
		service_location_id,
		distance,
		row_number() over (partition by suvida_id order by distance asc) as _idx
	from dw_dev.dev_jkizer_staging.patient_center_proximity pcp
	left join dw_dev.dev_jkizer_staging.service_locations sl 
        on pcp.service_location_address_id = sl.id
	left join dw_dev.dev_jkizer_staging.stg_elation_service_location sesl 
        on sl.elation_id = sesl.service_location_id
	group by suvida_id, service_location_id, distance
), mailing_list as (
    select distinct
        miep_idx.suvida_id,
        trim(pt.first_name) as first_name,
        case 
                when pt.middle_name is not null then trim(pt.middle_name)
                when pt.middle_initial is not null then trim(pt.middle_initial)
                else null
        end as middle_name,
        trim(pt.last_name) as last_name,
        pt.address_line_1,
        case
            when pt.address_line_2 is not null and pt.address_line_2 <> 'n/a' then pt.address_line_2
            else null
        end as address_line_2,
        case 
            when cities.city_name is not null then cities.city_name
            else pt.city
        end as city,
        case
            when cities.state_name is not null then cities.state_code
            else upper(pt.state)
        end as state,
        pt.zip,
        pt.provider_npi,
        coalesce(
            nullif(pt.location_name, 'Unassigned'),
            sesl.service_location_name
        ) as center,
        pml.mailer_date
    from max_intmdt_assignment_idx miep_idx 
    left join dw_dev.dev_jkizer.dim_patient pt 
        on miep_idx.suvida_id = pt.suvida_id
    left join dw_dev.dev_jkizer.patient_summary ps 
        on miep_idx.suvida_id = ps.suvida_id
    left join source_prod.misc.src_misc_cities cities 
        on trim(pt.city) = lower(cities.city_name)
    left join dw_dev.dev_jkizer_staging.stg_tbl_prod_marketbuilder_patient_mailing_list pml 
        on miep_idx.suvida_id = pml.suvida_id
    left join patient_service_location_distances psld 
        on miep_idx.suvida_id = psld.suvida_id and 
           psld._idx = 1
    inner join dw_dev.dev_jkizer_staging.patient_addresses pa
        on psld.suvida_id = pa.suvida_id and
	      lower(coalesce(pt.address_line_1, '')) = lower(pa.address_line_1_key) and
	      lower(coalesce(pt.address_line_2, '')) = lower(pa.address_line_2_key) and
	      lower(coalesce(pt.city, '')) = lower(pa.city_key) and
	      lower(coalesce(pt.state, '')) = lower(pa.state_key) and
	      lower(coalesce(pt.zip, '')) = lower(pa.zip_key) and	   
	      pa.source = 'Google'
    left join dw_dev.dev_jkizer_staging.stg_elation_service_location sesl 
        on psld.service_location_id = sesl.service_location_id
    where miep_idx.report_date between dateadd(day, -14, current_date()) and current_date()
)
select
    suvida_id,
    first_name,
    middle_name,
    last_name,
    address_line_1,
    address_line_2,
    city,
    state,
    zip,
    provider_npi,
    center,
    mailer_date,
    count(mailer_date) as count
from mailing_list
group by
    suvida_id,
    first_name,
    middle_name,
    last_name,
    address_line_1,
    address_line_2,
    city,
    state,
    zip,
    provider_npi,
    center,
    mailer_date
  );

