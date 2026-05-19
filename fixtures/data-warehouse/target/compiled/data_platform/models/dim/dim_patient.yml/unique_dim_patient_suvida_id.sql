
    
    

select
    suvida_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_patient
where suvida_id is not null
group by suvida_id
having count(*) > 1


