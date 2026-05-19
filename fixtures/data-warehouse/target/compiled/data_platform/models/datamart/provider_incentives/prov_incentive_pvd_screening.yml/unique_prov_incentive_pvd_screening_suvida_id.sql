
    
    

select
    suvida_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.prov_incentive_pvd_screening
where suvida_id is not null
group by suvida_id
having count(*) > 1


