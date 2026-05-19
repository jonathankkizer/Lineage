
  
    

create or replace transient table dw_dev.dev_jkizer.patient_report
    copy grants
    
    
    as (select
	suvida_id,
	elation_id,
	report_id,
	report_type,
	report_title,
	creation_datetime,
	document_date,
	signed_datetime,
	num_doc_tags,
	document_tag_values,
	is_echo,
	is_mammo_bilateral,
	is_mammo_right,
	is_mammo_left,
	is_quantaflo,
	is_a1c,
	is_cbp,
	is_ifobt_negative,
	is_ifobt_positive,
	is_fit_dna_negative,
	is_fit_dna_positive,
	is_sigmoidoscopy_negative,
	is_sigmoidoscopy_positive,
	is_colonoscopy_negative,
	is_colonoscopy_positive,
	is_colon_cancer_screen_unified,
	is_positive_diabetic_eye_screen,
	is_negative_diabetic_eye_screen,
	is_diabetic_eye_screen_unified,
	is_osteo_screen,
	consent_to_treatment_form_ind,
	consent_to_vaccine_form_ind,
	consent_to_physical_therapy_form_ind,
	consent_to_patient_procedure_form_ind,
	consent_to_telemedicine_az_form_ind,
	consent_to_telemedicine_tx_form_ind,
	consent_to_event_participation_form_ind,
	consent_to_electronic_text_communication_form_ind,
	consent_to_third_party_involvement_form_ind,
	consent_to_documentation_assistance_form_ind,
from dw_dev.dev_jkizer.fct_elation_report
    )
;


  