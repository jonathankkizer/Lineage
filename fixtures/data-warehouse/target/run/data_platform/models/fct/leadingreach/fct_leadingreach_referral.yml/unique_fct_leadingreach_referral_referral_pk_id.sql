
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    referral_pk_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_leadingreach_referral
where referral_pk_id is not null
group by referral_pk_id
having count(*) > 1



  
  
      
    ) dbt_internal_test