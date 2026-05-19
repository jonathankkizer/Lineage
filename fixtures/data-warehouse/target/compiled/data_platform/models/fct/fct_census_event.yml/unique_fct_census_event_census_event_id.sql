
    
    

select
    census_event_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_census_event
where census_event_id is not null
group by census_event_id
having count(*) > 1


