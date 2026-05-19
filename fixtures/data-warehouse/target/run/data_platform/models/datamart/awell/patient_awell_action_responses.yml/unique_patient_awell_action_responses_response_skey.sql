
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    response_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_awell_action_responses
where response_skey is not null
group by response_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test