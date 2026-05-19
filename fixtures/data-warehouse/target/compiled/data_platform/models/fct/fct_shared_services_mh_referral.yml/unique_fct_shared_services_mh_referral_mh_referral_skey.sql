
    
    

select
    mh_referral_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_shared_services_mh_referral
where mh_referral_skey is not null
group by mh_referral_skey
having count(*) > 1


