
  
    

create or replace transient table dw_dev.dev_jkizer.fct_patient_location
    copy grants
    
    
    as (with patient_service_location_distances as ( -- grab geo info for the nearest clinic to each patient
	select
		pcp.suvida_id,
		pcp.patient_address_id,
		elation_id,
		distance,
		row_number() over (partition by pcp.suvida_id, pcp.patient_address_id order by distance asc) as _idx
	from dw_dev.dev_jkizer_staging.patient_center_proximity pcp -- break these into sources
	left join dw_dev.dev_jkizer_staging.service_locations sl 
		on pcp.service_location_address_id = sl.id
	left join dw_dev.dev_jkizer_staging.patient_addresses pa 
		on pcp.patient_address_id = pa.address_id and
		   pa.source = 'Google'
	group by pcp.suvida_id, pcp.patient_address_id, elation_id, distance
), patient_location as ( -- combine Elation preferred location data w/ geo data, preferring Elation data when both are available
	select
		siw.suvida_id,
		sep.elation_id,
		sl_elation.service_location_id as preferred_location_id,
		sl_elation.service_location_name as preferred_location_name,
		sl_prox.service_location_id as nearest_location_id,
		sl_prox.service_location_name as nearest_location_name,
		sld.distance as nearest_location_distance,
		sl_prov.provider_location_name,
		coalesce(sl_elation.service_location_id, sl_prox.service_location_id) as location_id,
		trim(coalesce(sl_elation.service_location_name, sl_prox.service_location_name, sl_prov.provider_location_name)) as location_name,
		case 
			when sl_elation.service_location_name is not null then 'preferred_elation'
			when sl_elation.service_location_name is null and sl_prox.service_location_name is not null then 'nearest_geo'
			when sl_prov.provider_location_name is not null then 'provider_location'
			else null
		end as location_source_type,
		row_number() over (partition by siw.suvida_id order by coalesce(sep.last_modified_datetime, to_timestamp('1970-01-01')) desc) as _idx -- prefer records where elation ID is present
	from dw_dev.dev_jkizer.suvida_id_walk siw
	left join dw_dev.dev_jkizer_staging.stg_elation_patient sep
		on siw.member_id = sep.elation_id
		and siw.source = sep.source
		and sep._deletion_date is null
		and sep._is_test_patient = 0
		and sep._idx = 1
	left join dw_dev.dev_jkizer_staging.stg_elation_service_location sl_elation
		on sep.preferred_service_location_id = sl_elation.service_location_id
	left join patient_service_location_distances sld 
		on siw.suvida_id = sld.suvida_id
		and sld._idx = 1
	left join dw_dev.dev_jkizer_staging.stg_elation_service_location sl_prox
		on sld.elation_id = sl_prox.service_location_id
	left join dw_dev.dev_jkizer.fct_patient_provider sl_prov
		on siw.suvida_id = sl_prov.suvida_id
	where siw.source != 'SalesForce'
)
select 
	suvida_id,
	elation_id,
	preferred_location_id,
	preferred_location_name,
	nearest_location_id,
	nearest_location_name,
	nearest_location_distance,
	provider_location_name,
	location_id,
	location_source_type,
	location_name
from patient_location pl
where _idx = 1
    )
;


  