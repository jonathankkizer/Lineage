
    
    

select
    attestation_opportunity_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.attestation_opportunity
where attestation_opportunity_skey is not null
group by attestation_opportunity_skey
having count(*) > 1


