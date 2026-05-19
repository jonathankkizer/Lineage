
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    pt_referral_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_shared_services_pt_referral
where pt_referral_skey is not null
group by pt_referral_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test