
    
    

select
    encounter_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_encounter
where encounter_id is not null
group by encounter_id
having count(*) > 1


