
    
    

select
    claims_diagnosis_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_claims_diagnosis
where claims_diagnosis_skey is not null
group by claims_diagnosis_skey
having count(*) > 1


