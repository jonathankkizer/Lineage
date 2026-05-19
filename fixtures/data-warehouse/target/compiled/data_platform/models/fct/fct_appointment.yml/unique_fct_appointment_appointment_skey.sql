
    
    

select
    appointment_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_appointment
where appointment_skey is not null
group by appointment_skey
having count(*) > 1


