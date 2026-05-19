
    
    

select
    claim_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.revenue_cycle_candid_payer_contract
where claim_id is not null
group by claim_id
having count(*) > 1


