
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    plan_code_mapping_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_sharepoint_payer_plan_code
where plan_code_mapping_skey is not null
group by plan_code_mapping_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test