
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    service_line_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_candid_health_export_service_line_projected_financials
where service_line_id is not null
group by service_line_id
having count(*) > 1



  
  
      
    ) dbt_internal_test