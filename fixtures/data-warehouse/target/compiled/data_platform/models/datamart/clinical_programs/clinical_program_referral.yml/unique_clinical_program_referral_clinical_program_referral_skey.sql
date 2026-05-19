
    
    

select
    clinical_program_referral_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.clinical_program_referral
where clinical_program_referral_skey is not null
group by clinical_program_referral_skey
having count(*) > 1


