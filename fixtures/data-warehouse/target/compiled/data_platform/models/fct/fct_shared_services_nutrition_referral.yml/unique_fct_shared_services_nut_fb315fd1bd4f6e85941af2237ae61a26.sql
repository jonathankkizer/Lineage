
    
    

select
    nutrition_referral_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_shared_services_nutrition_referral
where nutrition_referral_skey is not null
group by nutrition_referral_skey
having count(*) > 1


