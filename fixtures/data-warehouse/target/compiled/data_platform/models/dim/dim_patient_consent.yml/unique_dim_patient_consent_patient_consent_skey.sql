
    
    

select
    patient_consent_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_patient_consent
where patient_consent_skey is not null
group by patient_consent_skey
having count(*) > 1


