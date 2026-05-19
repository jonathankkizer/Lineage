
    
    

select
    office_messages_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_office_message
where office_messages_id is not null
group by office_messages_id
having count(*) > 1


