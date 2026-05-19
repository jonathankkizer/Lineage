
    
    

select
    prov_incentive_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.prov_incentive_combined
where prov_incentive_id is not null
group by prov_incentive_id
having count(*) > 1


