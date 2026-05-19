
    
    

select
    lab_order_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_lab_order
where lab_order_skey is not null
group by lab_order_skey
having count(*) > 1


