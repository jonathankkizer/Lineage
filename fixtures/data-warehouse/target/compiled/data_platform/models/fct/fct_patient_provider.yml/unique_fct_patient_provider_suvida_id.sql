
    
    

select
    suvida_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_patient_provider
where suvida_id is not null
group by suvida_id
having count(*) > 1


