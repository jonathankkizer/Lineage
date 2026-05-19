select
	suvida_id,
	immunization_name,
	ordering_physician_id,
	eu.user_name as ordering_physician_name,
	administering_physician_id,
	administer.user_name as administering_physician_name,
	description as immunization_description,
	creation_datetime,
	administered_datetime,
	date(administered_datetime) as administered_date,
	last_modified_datetime,
	qty as quantity,
	qty_units as quantity_units,
	lot_number,
	manufacturer_name,
	reason,
	expiration_date,
	vis,
	method,
	site,
	notes,
	cvx,
	vfc_eligibility,
	info_source,
	created_by_user_id,
	created_by.user_name as created_by_user_name
from dw_dev.dev_jkizer_staging.stg_elation_patient_immunization pi
left join dw_dev.dev_jkizer_staging.stg_elation_user eu 
	on eu.physician_id = pi.ordering_physician_id 
left join dw_dev.dev_jkizer_staging.stg_elation_user administer 
	on administer.physician_id = pi.administering_physician_id 
left join dw_dev.dev_jkizer_staging.stg_elation_user created_by 
	on created_by.user_id = pi.created_by_user_id 
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on pi.patient_id = siw.member_id
	and siw.source = 'Elation'
where pi.deletion_datetime is null