select
    awell.patient_profile_id,
    p.patient_id as awell_patient_id,
    awell.elation_id,
    dim.suvida_id,
    awell.full_name,
    awell.first_name,
    awell.last_name,
    awell.birth_date,
    p.status,
    dim.age_year,
    dim.location_name,
    dim.location_state, 
    dim.market_name,
    dim.gender,
    dim.elation_status,
    dim.elation_insurance_name,
    dim.elation_patient_url,
    dim.is_active_enrollment,
    dim.is_active_assignment,
    dim.payer_name,
    dim.provider_name
from dw_dev.dev_jkizer_staging.stg_awell_patient_profiles awell 
left join dw_dev.dev_jkizer_staging.stg_awell_patients p 
    on p.profile_id = awell.patient_profile_id
left join dw_dev.dev_jkizer.suvida_id_walk siw
    on awell.elation_id = siw.member_id and siw.source = 'Elation'
left join dw_dev.dev_jkizer.dim_patient dim 
    on dim.suvida_id = siw.suvida_id