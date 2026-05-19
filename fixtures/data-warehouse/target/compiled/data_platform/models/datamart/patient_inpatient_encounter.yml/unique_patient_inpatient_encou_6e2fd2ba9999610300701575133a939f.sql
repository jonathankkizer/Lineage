
    
    

select
    patient_inpatient_encounter_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_inpatient_encounter
where patient_inpatient_encounter_skey is not null
group by patient_inpatient_encounter_skey
having count(*) > 1


