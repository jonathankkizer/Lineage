
    
    

select
    member_month_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_member_month
where member_month_skey is not null
group by member_month_skey
having count(*) > 1


