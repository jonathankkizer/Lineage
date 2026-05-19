
    
    

select
    quality_measure_report_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_quality_measure
where quality_measure_report_skey is not null
group by quality_measure_report_skey
having count(*) > 1


