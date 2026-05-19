select 
    patient_id, 
    id as patient_email_id, 
    type, 
    address, 
    created_at,
    updated_at
from source_prod.leadingreach.patient_email