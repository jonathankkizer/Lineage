
    
    

select
    id as unique_field,
    count(*) as n_records

from dw_prod.dw.intmdt_teams_call_record
where id is not null
group by id
having count(*) > 1


