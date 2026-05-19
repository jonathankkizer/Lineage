
    
    

select
    payer_uuid as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_export_payer
where payer_uuid is not null
group by payer_uuid
having count(*) > 1


