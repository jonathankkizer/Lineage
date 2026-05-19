select
    suvida_id,
    elation_id,
    date_patched as event_at
from source_prod.tags.patient_tag_updates
where date_patched is not null