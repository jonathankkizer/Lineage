
    
    

select
    clinical_program_enrollment_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.clinical_program_enrollment
where clinical_program_enrollment_skey is not null
group by clinical_program_enrollment_skey
having count(*) > 1


