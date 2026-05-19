
    
    

select
    activity_key as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_quality_review_activity
where activity_key is not null
group by activity_key
having count(*) > 1


