
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    monthly_membership_adk_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.monthly_membership_adk
where monthly_membership_adk_skey is not null
group by monthly_membership_adk_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test