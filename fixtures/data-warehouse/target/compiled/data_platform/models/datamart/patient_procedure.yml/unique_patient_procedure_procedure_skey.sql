
    
    

select
    procedure_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_procedure
where procedure_skey is not null
group by procedure_skey
having count(*) > 1


