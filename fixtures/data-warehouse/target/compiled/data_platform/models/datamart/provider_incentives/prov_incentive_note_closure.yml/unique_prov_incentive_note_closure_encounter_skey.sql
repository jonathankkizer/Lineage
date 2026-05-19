
    
    

select
    encounter_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.prov_incentive_note_closure
where encounter_skey is not null
group by encounter_skey
having count(*) > 1


