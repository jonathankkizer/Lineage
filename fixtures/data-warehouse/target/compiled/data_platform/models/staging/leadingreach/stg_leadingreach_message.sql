select 
    id as message_id, 
    type as message_type, 
    status, 
    direction, 
    comment,
    sent_on, 
    created_at, 
    updated_at, 
    sender_organization, 
    recipient_organization, 
    parent,
    referral, 
    patient
from source_prod.leadingreach.message