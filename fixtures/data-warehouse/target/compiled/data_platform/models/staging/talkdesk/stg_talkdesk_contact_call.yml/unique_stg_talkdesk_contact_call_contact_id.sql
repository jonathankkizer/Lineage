
    
    

select
    contact_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_talkdesk_contact_call
where contact_id is not null
group by contact_id
having count(*) > 1


