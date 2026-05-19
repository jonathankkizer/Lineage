
  
    

create or replace transient table dw_dev.dev_jkizer.patient_claim_er
    copy grants
    
    
    as (select
	eds.*,
	stl.parent_organization,
	stl.address,
	stl.city,
	stl.state,
	stl.zip_code,
	stl.latitude,
	stl.longitude,
	stp.npi,
	stp.provider_first_name,
	stp.provider_last_name,
	stp.practice_affiliation,
	stp.specialty,
	stp.sub_specialty,
from dw_dev.dev_jkizer_staging.stg_tuva_encounter eds
left join dw_dev.dev_jkizer_staging.stg_tuva_location stl
	on eds.facility_id = stl.location_id
left join dw_dev.dev_jkizer_staging.stg_tuva_practitioner stp 
	on eds.attending_provider_id = stp.practitioner_id
where encounter_group = 'outpatient'
and encounter_type = 'emergency department'
    )
;


  