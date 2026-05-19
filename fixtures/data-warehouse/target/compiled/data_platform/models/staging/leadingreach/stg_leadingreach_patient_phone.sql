select 
    patient_id, 
    id as patient_phone_id, 
    type, 
    number, 
    extension,
    created_at,
    updated_at
from source_prod.leadingreach.patient_phone