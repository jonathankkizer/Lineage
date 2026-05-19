
  create or replace   view dw_dev.dev_jkizer.do_not_call_patient_outreach_numbers_daily
  
  copy grants
  
  
  as (
    

with area_codes as (
    select distinct substr(phone, 1, 3) as area_code
    from dw_dev.dev_jkizer.dim_patient
    where phone is not null
    group by substr(phone, 1, 3)
) 

select
    shvpon.suvida_id,
    concat(dncr.area_code, dncr.phone_number) as phone_number 
from source_prod.misc.do_not_call_registry dncr
inner join area_codes ac on dncr.area_code = ac.area_code
inner join source_prod.misc.patient_outreach_numbers_daily shvpon on concat(dncr.area_code, dncr.phone_number) = shvpon.phone
  );

