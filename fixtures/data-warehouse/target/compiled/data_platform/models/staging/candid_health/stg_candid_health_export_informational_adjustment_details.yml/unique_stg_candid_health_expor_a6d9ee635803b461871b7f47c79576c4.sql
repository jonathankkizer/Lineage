
    
    

select
    adjustment_detail_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_informational_adjustment_details
where adjustment_detail_id is not null
group by adjustment_detail_id
having count(*) > 1


