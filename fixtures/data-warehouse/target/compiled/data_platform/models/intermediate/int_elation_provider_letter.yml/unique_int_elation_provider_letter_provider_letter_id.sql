
    
    

select
    provider_letter_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.int_elation_provider_letter
where provider_letter_id is not null
group by provider_letter_id
having count(*) > 1


