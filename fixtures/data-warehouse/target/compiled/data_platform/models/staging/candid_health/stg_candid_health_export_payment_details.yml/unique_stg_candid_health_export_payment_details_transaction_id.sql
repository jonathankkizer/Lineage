
    
    

select
    transaction_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_payment_details
where transaction_id is not null
group by transaction_id
having count(*) > 1


