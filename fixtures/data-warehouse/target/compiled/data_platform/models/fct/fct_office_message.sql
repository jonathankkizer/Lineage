select 
    office_messages_id, 
    siw.suvida_id, 
    om.elation_id,
    thread_id,
    text,
    urgent,
    sender_id,
    datetime_sent,
    post_datetime,
    om.creation_datetime,
    om.created_by_user_id,
    om.deletion_datetime,
    om.deleted_by_user_id,
    om.signed_datetime,
    om.signed_by_user_id,
    om._idx
from dw_dev.dev_jkizer_staging.stg_elation_office_messages om
inner join dw_dev.dev_jkizer_staging.stg_elation_patient u
    on om.elation_id = u.elation_id
left join dw_dev.dev_jkizer.suvida_id_walk siw
    on om.elation_id = siw.member_id
    and siw.source = 'Elation'