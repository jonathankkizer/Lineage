
    
    

select
    guia_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_guia
where guia_skey is not null
group by guia_skey
having count(*) > 1


