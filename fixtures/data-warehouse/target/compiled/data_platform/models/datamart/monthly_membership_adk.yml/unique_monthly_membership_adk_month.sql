
    
    

select
    month as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.monthly_membership_adk
where month is not null
group by month
having count(*) > 1


