
    
    

select
    airtable_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_shared_services_mh_referral
where airtable_id is not null
group by airtable_id
having count(*) > 1


