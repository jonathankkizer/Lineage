
    
    

select
    provider_letter_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_letter
where provider_letter_skey is not null
group by provider_letter_skey
having count(*) > 1


