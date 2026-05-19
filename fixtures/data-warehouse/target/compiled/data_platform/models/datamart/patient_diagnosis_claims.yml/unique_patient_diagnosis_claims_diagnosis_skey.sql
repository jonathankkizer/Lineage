
    
    

select
    diagnosis_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_diagnosis_claims
where diagnosis_skey is not null
group by diagnosis_skey
having count(*) > 1


