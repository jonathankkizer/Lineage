
    
    

select
    encounter_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_encounter
where encounter_skey is not null
group by encounter_skey
having count(*) > 1


