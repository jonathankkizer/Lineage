
    
    

select
    all_orders_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.intmdt_elation_all_orders
where all_orders_skey is not null
group by all_orders_skey
having count(*) > 1


