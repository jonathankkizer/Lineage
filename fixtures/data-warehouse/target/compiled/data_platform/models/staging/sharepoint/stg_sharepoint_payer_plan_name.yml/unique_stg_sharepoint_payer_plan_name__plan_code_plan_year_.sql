
    
    

select
    (plan_code || '-' || plan_year) as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_name
where (plan_code || '-' || plan_year) is not null
group by (plan_code || '-' || plan_year)
having count(*) > 1


