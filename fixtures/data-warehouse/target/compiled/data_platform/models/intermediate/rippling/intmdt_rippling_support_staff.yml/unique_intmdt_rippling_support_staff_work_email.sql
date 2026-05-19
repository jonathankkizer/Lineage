
    
    

select
    work_email as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.intmdt_rippling_support_staff
where work_email is not null
group by work_email
having count(*) > 1


