
    
    

select
    claim_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer_staging.stg_alignment_claims_medical
where claim_id is not null
group by claim_id
having count(*) > 1


