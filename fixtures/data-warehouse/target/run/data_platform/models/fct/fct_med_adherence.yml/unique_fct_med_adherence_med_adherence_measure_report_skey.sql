
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    med_adherence_measure_report_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_med_adherence
where med_adherence_measure_report_skey is not null
group by med_adherence_measure_report_skey
having count(*) > 1



  
  
      
    ) dbt_internal_test