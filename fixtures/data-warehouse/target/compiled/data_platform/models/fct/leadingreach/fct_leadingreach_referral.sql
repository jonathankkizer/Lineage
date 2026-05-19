select 
    ref.message_id, 
    ref.referral_pk_id, 
    ref.type as referral_type, 
    ref.reason as referral_reason, 
    msg.message_type, 
    msg.status, 
    case when appt.appointment_id is not null then true else false end as is_appointment_scheduled,
    msg.direction,
    priority,
    insurance_provider, 
    insurance_group_number, 
    insurance_authorization_number, 
    prov.provider_id, 
    prov.full_name as provider_name, 
    prov.specialty_classification, 
    prov.specialization,
    date(prov.created_at) as provider_created_at,
    location.organization_name,
    location.location_id as referred_location_id, 
    location.location_name as referred_location_name, 
    behalf.provider_id as on_behalf_of_provider_id,
    behalf.full_name as on_behalf_of_provider_name, 
    behalf.default_location_name as on_behalf_of_location,
    referral_id, 
    date(ref.created_at) as referral_created_at,
    date(ref.updated_at) as referral_updated_at,
    patient.patient_id, 
    patient.account_number,
    patient.elation_id,
    patient.full_name as patient_full_name,
    patient.dob as patient_dob,
    date(patient.created_at) as patient_created_at
from dw_dev.dev_jkizer_staging.stg_leadingreach_referral ref 
left join  dw_dev.dev_jkizer_staging.stg_leadingreach_message msg
    on msg.message_id = ref.message_id
left join dw_dev.dev_jkizer.dim_leadingreach_patient patient 
    on patient.patient_id = REGEXP_SUBSTR(msg.patient, '/([0-9]+)$', 1, 1, 'e', 1)
left join dw_dev.dev_jkizer.dim_leadingreach_provider prov 
    on prov.provider_id = REGEXP_SUBSTR(ref.provider, '/([0-9]+)$', 1, 1, 'e', 1)
left join dw_dev.dev_jkizer.dim_leadingreach_location location 
    on location.location_id = REGEXP_SUBSTR(ref.location, '/([0-9]+)$', 1, 1, 'e', 1)
left join dw_dev.dev_jkizer.dim_leadingreach_provider behalf 
    on behalf.provider_id = REGEXP_SUBSTR(ref.on_behalf_of_provider, '/([0-9]+)$', 1, 1, 'e', 1)
left join  dw_dev.dev_jkizer_staging.stg_leadingreach_message_appointment appt 
    on appt.message_id = ref.message_id 
group by all