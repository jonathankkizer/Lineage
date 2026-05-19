
    
    

select
    callsid as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_talkdesk_call
where callsid is not null
group by callsid
having count(*) > 1


