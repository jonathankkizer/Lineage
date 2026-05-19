
    
    

select
    patient_communication_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.intmdt_patient_communication
where patient_communication_skey is not null
group by patient_communication_skey
having count(*) > 1


