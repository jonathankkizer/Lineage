
    
    

select
    suvida_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_summary
where suvida_id is not null
group by suvida_id
having count(*) > 1


