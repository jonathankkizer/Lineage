
    
    

select
    patient_clinical_program_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_clinical_program
where patient_clinical_program_skey is not null
group by patient_clinical_program_skey
having count(*) > 1


