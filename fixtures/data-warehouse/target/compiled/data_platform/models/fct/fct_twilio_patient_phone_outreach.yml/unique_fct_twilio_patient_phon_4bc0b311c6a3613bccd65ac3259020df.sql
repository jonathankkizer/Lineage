
    
    

select
    twilio_phone_outreach_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_twilio_patient_phone_outreach
where twilio_phone_outreach_skey is not null
group by twilio_phone_outreach_skey
having count(*) > 1


