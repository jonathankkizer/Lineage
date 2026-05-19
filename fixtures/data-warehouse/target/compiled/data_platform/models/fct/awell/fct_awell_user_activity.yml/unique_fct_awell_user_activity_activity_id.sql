
    
    

select
    activity_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_awell_user_activity
where activity_id is not null
group by activity_id
having count(*) > 1


