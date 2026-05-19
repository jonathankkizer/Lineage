
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    nutrition_referral_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_shared_services_nutrition_referral
where nutrition_referral_skey is not null
group by nutrition_referral_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test