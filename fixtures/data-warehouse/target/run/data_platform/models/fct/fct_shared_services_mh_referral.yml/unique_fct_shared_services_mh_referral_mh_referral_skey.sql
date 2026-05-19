
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    mh_referral_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_shared_services_mh_referral
where mh_referral_skey is not null
group by mh_referral_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test