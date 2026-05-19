/*
    Purpose: staging model from Talkdesk contact center.
    Primary Key: id
    Grain: one row per user (includes patients)
*/


select
    id,
    name
from fivetran_source_prod.talkdesk.users