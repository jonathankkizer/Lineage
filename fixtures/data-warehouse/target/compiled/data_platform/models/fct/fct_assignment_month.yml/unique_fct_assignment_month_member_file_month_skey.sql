
    
    

select
    member_file_month_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_assignment_month
where member_file_month_skey is not null
group by member_file_month_skey
having count(*) > 1


