
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    payer_uuid as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_export_payer
where payer_uuid is not null
group by payer_uuid
having count(*) > 1



  
  
      
    ) dbt_internal_test