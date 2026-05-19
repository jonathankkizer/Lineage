
    
    

select
    consent_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_consent
where consent_skey is not null
group by consent_skey
having count(*) > 1


