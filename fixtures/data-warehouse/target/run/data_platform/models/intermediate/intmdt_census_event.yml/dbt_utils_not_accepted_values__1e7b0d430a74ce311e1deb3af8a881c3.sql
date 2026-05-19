
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
with all_values as (

    select distinct
        source_member_id as value_field

    from dw_dev.dev_jkizer.intmdt_census_event

),

validation_errors as (

    select
        value_field

    from all_values
    where value_field in (
        'NULLID'
        )

)

select *
from validation_errors


  
  
      
    ) dbt_internal_test