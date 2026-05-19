
    
    

select
    encounter_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_candid_health_claims
where encounter_id is not null
group by encounter_id
having count(*) > 1


