
    
    

select
    PATIENT_ID as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.int_bamboo_roster
where PATIENT_ID is not null
group by PATIENT_ID
having count(*) > 1


