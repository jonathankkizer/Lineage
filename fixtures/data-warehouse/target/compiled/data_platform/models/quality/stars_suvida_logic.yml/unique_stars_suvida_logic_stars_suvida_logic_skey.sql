
    
    

select
    stars_suvida_logic_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_quality.stars_suvida_logic
where stars_suvida_logic_skey is not null
group by stars_suvida_logic_skey
having count(*) > 1


