
  
    

create or replace transient table dw_dev.dev_jkizer.patient_leadingreach_referrals
    copy grants
    
    
    as (select 
    fct.*,
    patient.suvida_id, 
    patient.phone as patient_phone, 
    patient.location_name as patient_location_name, 
    patient.location_state as patient_location_state, 
    patient.market_name as patient_market_name, 
    patient.provider_name as patient_assigned_provider
from dw_dev.dev_jkizer.fct_leadingreach_referral fct
left join dw_dev.dev_jkizer.suvida_id_walk siw 
    on siw.member_id = fct.elation_id 
    and siw.source = 'Elation'
left join dw_dev.dev_jkizer.dim_patient patient 
    on patient.suvida_id = siw.suvida_id
    )
;


  