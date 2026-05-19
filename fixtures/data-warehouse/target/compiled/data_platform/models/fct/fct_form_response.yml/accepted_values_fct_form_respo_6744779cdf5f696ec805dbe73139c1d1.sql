
    
    

with all_values as (

    select
        form_family as value_field,
        count(*) as n_records

    from dw_dev.dev_jkizer.fct_form_response
    group by form_family

)

select *
from all_values
where value_field not in (
    'abc_6_scale','abc_scale','consent_clinician_incapacity','consent_documentation_assist','consent_electronic_text_comm','consent_event_participation','consent_patient_acknowledgement','consent_patient_acknowledgement_opt_out','consent_phi_disclose','consent_phi_receive','consent_phi_restrict','consent_procedure','consent_pt','consent_social_care','consent_telemed','consent_third_party','consent_treatment','consent_vaccine','controlled_substance_agreement','dash','dhi','faam','fap','gad_7','hra','insurance_information','intake_form','lefs','mdq','ndi','notice_of_privacy_practices','oswestry','patient_preference_form','patient_provider_list','patient_registration','patient_transfer','patient_waiver_treatment_refusal','phq_2','phq_9','pt_attendance_policy','pt_intake','sdoh_ahc','supplemental'
)


