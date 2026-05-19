select 
    date_created, 
    action,
    id as patient_id,
    prev_state, 
    new_state 
from source_prod.leadingreach.action_log