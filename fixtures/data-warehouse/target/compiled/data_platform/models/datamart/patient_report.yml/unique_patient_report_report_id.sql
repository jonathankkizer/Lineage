
    
    

select
    report_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_report
where report_id is not null
group by report_id
having count(*) > 1


