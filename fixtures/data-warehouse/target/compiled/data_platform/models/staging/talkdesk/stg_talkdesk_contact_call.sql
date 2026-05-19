/*
    Purpose: staging model from Talkdesk contact center.
    Primary Key: contact_id
    Grain: one row per contact per call interaction
*/

select
    contact_id,
    interaction_id,
    user_id
from fivetran_source_prod.talkdesk.contact_call