
    
    

select
    referral_pk_id as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.patient_leadingreach_referrals
where referral_pk_id is not null
group by referral_pk_id
having count(*) > 1


