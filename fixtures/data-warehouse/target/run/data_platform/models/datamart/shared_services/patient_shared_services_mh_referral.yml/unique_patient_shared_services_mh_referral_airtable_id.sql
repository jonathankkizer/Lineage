
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    airtable_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_shared_services_mh_referral
where airtable_id is not null
group by airtable_id
having count(*) > 1



  
  
      
    ) dbt_internal_test