select
    suvida_id,
    elation_id,
    date_patched as event_at
from source_prod.insurance.patient_insurance_updates
where date_patched is not null