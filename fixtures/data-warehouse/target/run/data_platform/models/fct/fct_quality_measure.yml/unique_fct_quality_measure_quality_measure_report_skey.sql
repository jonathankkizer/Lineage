
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    quality_measure_report_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_quality_measure
where quality_measure_report_skey is not null
group by quality_measure_report_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test