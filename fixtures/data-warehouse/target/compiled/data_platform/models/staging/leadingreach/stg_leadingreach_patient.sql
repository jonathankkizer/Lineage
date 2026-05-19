select 
    id as patient_id, 
    account,
    first_name,
    middle_name,
    last_name, 
    given_name,
    name_prefix,
    name_suffix, 
    dob, 
    gender,
    postal_code,
    is_allow_text_appointment_reminders, 
    is_allow_email_appointment_reminders, 
    created_at, 
    updated_at,
    organization
from source_prod.leadingreach.patient