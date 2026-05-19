
  
    

create or replace transient table dw_dev.dev_jkizer.dim_leadingreach_patient
    copy grants
    
    
    as (select 
    patient.patient_id, 
    account as account_number,
    elation.elation_id,
    concat(patient.first_name, ' ', patient.last_name) as full_name,
    patient.first_name,
    patient.middle_name,
    patient.last_name, 
    patient.dob, 
    patient.postal_code, 
    email.address as email_address,
    phone.number as phone_number, 
    is_allow_text_appointment_reminders, 
    is_allow_email_appointment_reminders, 
    patient.created_at, 
    patient.updated_at,
from dw_dev.dev_jkizer_staging.stg_leadingreach_patient patient
left join dw_dev.dev_jkizer_staging.stg_leadingreach_patient_email email 
    on email.patient_id = patient.patient_id 
left join dw_dev.dev_jkizer_staging.stg_leadingreach_patient_phone phone 
    on phone.patient_id = patient.patient_id and phone.type = 'main'
left join dw_dev.dev_jkizer_staging.stg_elation_patient elation 
    on elation.elation_id = patient.account
    )
;


  