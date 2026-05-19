
    
    

select
    patient_period_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_monthly_clinical_values
where patient_period_skey is not null
group by patient_period_skey
having count(*) > 1


