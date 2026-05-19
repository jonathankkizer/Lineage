
    
    

select
    id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_rippling_users
where id is not null
group by id
having count(*) > 1


