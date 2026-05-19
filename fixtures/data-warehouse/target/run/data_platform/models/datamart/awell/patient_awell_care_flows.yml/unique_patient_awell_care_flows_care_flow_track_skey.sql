
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    care_flow_track_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_awell_care_flows
where care_flow_track_skey is not null
group by care_flow_track_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test