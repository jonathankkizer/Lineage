
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select med_adherence_measure_report_skey
from dw_dev.dev_jkizer.fct_med_adherence
where med_adherence_measure_report_skey is null



  
  
      
    ) dbt_internal_test