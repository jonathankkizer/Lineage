
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    callsid as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_talkdesk_call
where callsid is not null
group by callsid
having count(*) > 1



  
  
      
    ) dbt_internal_test