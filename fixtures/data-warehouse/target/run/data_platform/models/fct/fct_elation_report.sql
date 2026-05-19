
  
    

create or replace transient table dw_dev.dev_jkizer.fct_elation_report
    copy grants
    
    
    as (with report_doc_tags as (
    select
        ser.report_id,
        count(dt.document_tag_id) as num_doc_tags,
        max(case when lower(dt.document_tag_value) = 'echocardiogram (suvida)' then 1 else 0 end) as is_echo,
        max(case when lower(dt.document_tag_value) in ('mammogram: bilateral result (abnormal)','mammogram: bilateral result (normal)') then 1 else 0 end) as is_mammo_bilateral,
        max(case when lower(dt.document_tag_value) = 'Mammogram: Unilateral Result Right  (Suvida)' then 1 else 0 end) as is_mammo_right,
        max(case when lower(dt.document_tag_value) = 'Mammogram: Unilateral Result Left (Suvida)' then 1 else 0 end) as is_mammo_left,
        max(case when lower(dt.document_tag_value) like '%quantaflo%' then 1 else 0 end) as is_quantaflo,
        max(case when lower(dt.document_tag_value) = 'a1c (suvida)' then 1 else 0 end) as is_a1c,
        max(case when lower(dt.document_tag_value) = 'cbp (suvida)' then 1 else 0 end) as is_cbp,
		max(case when lower(dt.document_tag_value) = 'ifobt,gfobt,fit (negative)' then 1 else 0 end) as is_ifobt_negative,
        max(case when lower(dt.document_tag_value) = 'ifobt,gfobt,fit (positive)' then 1 else 0 end) as is_ifobt_positive,
		max(case when lower(dt.document_tag_value) = 'flexible sigmoidoscopy (result: negative)' then 1 else 0 end) as is_sigmoidoscopy_negative,
        max(case when lower(dt.document_tag_value) = 'flexible sigmoidoscopy (result: positive)' then 1 else 0 end) as is_sigmoidoscopy_positive,
		max(case when lower(dt.document_tag_value) = 'colonoscopy (result: negative)' then 1 else 0 end) as is_colonoscopy_negative,
        max(case when lower(dt.document_tag_value) = 'colonoscopy (result: positive)' then 1 else 0 end) as is_colonoscopy_positive,
        max(case when lower(dt.document_tag_value) = 'fit dna (result: negative)' then 1 else 0 end) as is_fit_dna_negative,
        max(case when lower(dt.document_tag_value) = 'fit dna (result: positive)' then 1 else 0 end) as is_fit_dna_positive,
        max(case when lower(dt.document_tag_value)= 'eye exam (positive for retinopathy)' then 1 else 0 end) as is_positive_diabetic_eye_screen,
        max(case when lower(dt.document_tag_value)= 'eye exam (negative for retinopathy)' then 1 else 0 end) as is_negative_diabetic_eye_screen,
        max(case when lower(dt.document_tag_value) = 'osteoporosis screening (suvida)' then 1 else 0 end) as is_osteo_screen,
        max(case when lower(dt.document_tag_value) = 'adt document (suvida)' then 1 else 0 end) as is_adt_document,
        max(case when lower(dt.document_tag_value) = 'refill request document (suvida)' then 1 else 0 end) as is_refill_request,
        max(case when lower(dt.document_tag_value) = 'diabetic kidney evaluation: egfr (suvida)' then 1 else 0 end) as is_diabetic_kidney_egfr,
        max(case when lower(dt.document_tag_value) = 'diabetic kidney evaluation: urine microalbumin (suvida)' then 1 else 0 end) as is_diabetic_kidney_microalbumin,
        max(case when lower(document_tag_value) = 'advance care planning - document on file' then 1 else 0 end) as is_advance_care_plan,
        -- these are based on DocTags mappings contact Raymond Donato for background
        listagg(dt.document_tag_value, ' | ') as document_tag_values,
    from dw_dev.dev_jkizer_staging.stg_elation_report ser
    inner join dw_dev.dev_jkizer_staging.stg_elation_br_report_document_tag br
        on ser.report_id = br.report_id
        and br._rn = 1
    inner join dw_dev.dev_jkizer_staging.stg_elation_document_tag dt
        on br.document_tag_id = dt.document_tag_id
        and dt._rn = 1
    group by ser.report_id
)
select
    siw.suvida_id,
    ser.patient_id as elation_id,
    ser.report_id,
    ser.report_type,
    ser.report_title,
    ser.creation_datetime,
    ser.document_date,
    ser.signed_datetime,
    coalesce(rdt.num_doc_tags, 0) as num_doc_tags,
    rdt.document_tag_values,
    coalesce(
        rdt.is_echo, 
        case when lower(ser.report_title) like '%echo-%' then 1 else 0 end, -- clean up
        0 
    ) as is_echo,
    coalesce(rdt.is_mammo_bilateral, 0) as is_mammo_bilateral,
    coalesce(rdt.is_mammo_right,0) as is_mammo_right,
    coalesce(rdt.is_mammo_left,0) as is_mammo_left,
    coalesce(rdt.is_quantaflo, 0) as is_quantaflo,
    coalesce(rdt.is_a1c, 0) as is_a1c,
    coalesce(rdt.is_cbp, 0) as is_cbp,
	coalesce(rdt.is_ifobt_negative,0) as is_ifobt_negative,
    coalesce(rdt.is_ifobt_positive,0) as is_ifobt_positive,
	coalesce(rdt.is_fit_dna_negative,0) as is_fit_dna_negative,
    coalesce(rdt.is_fit_dna_positive,0) as is_fit_dna_positive,
	coalesce(rdt.is_Sigmoidoscopy_negative,0) as is_Sigmoidoscopy_negative,
    coalesce(rdt.is_Sigmoidoscopy_positive,0) as is_Sigmoidoscopy_positive,
    coalesce(rdt.is_colonoscopy_negative,0) as is_colonoscopy_negative,
    coalesce(rdt.is_colonoscopy_positive,0) as is_colonoscopy_positive,
	coalesce(rdt.is_ifobt_negative,rdt.is_ifobt_positive,rdt.is_sigmoidoscopy_negative,rdt.is_sigmoidoscopy_positive,rdt.is_colonoscopy_negative,rdt.is_colonoscopy_positive,rdt.is_fit_dna_negative,rdt.is_fit_dna_positive, 0) as is_colon_cancer_screen_unified,
    coalesce(rdt.is_positive_diabetic_eye_screen,0) as is_positive_diabetic_eye_screen,
    coalesce(rdt.is_negative_diabetic_eye_screen,0) as is_negative_diabetic_eye_screen,
    coalesce(rdt.is_negative_diabetic_eye_screen,rdt.is_positive_diabetic_eye_screen,0) as is_diabetic_eye_screen_unified,
    coalesce(rdt.is_osteo_screen, 0) as is_osteo_screen,
    coalesce(rdt.is_advance_care_plan,0) as is_advance_care_plan,
    iff(lower(ser.report_title) like '%consent to treatment%', 1, 0) as consent_to_treatment_form_ind,
    iff(lower(ser.report_title) like '%vaccine consent form%', 1, 0) as consent_to_vaccine_form_ind,
    iff(lower(ser.report_title) like '%physical therapy consent%', 1, 0) as consent_to_physical_therapy_form_ind,
    iff(lower(ser.report_title) like '%patient procedure consent%', 1, 0) as consent_to_patient_procedure_form_ind,
    iff(lower(ser.report_title) like '%informed consent for telemedicine medical services (az)%', 1, 0) as consent_to_telemedicine_az_form_ind,
    iff(lower(ser.report_title) like '%informed consent for telemedicine medical services (tx)%', 1, 0) as consent_to_telemedicine_tx_form_ind,
    iff(lower(ser.report_title) like '%event participation consent%', 1, 0) as consent_to_event_participation_form_ind,
    iff(lower(ser.report_title) like '%electronic and text communication consent form%', 1, 0) as consent_to_electronic_text_communication_form_ind,
    iff(lower(ser.report_title) like '%consent for third party involvement%', 1, 0) as consent_to_third_party_involvement_form_ind,
    iff(lower(ser.report_title) like '%consent for documentation assistance%', 1, 0) as consent_to_documentation_assistance_form_ind,
    iff(lower(ser.report_title) like '%authorization to receive protected health information%', 1, 0) as consent_to_receive_phi_form_ind,
    iff(lower(ser.report_type) like '%oldrecord%', 1, 0) as is_old_record_available
from dw_dev.dev_jkizer_staging.stg_elation_report ser 
inner join dw_dev.dev_jkizer.suvida_id_walk siw 
    on ser.source = siw.source 
    and to_varchar(ser.patient_id) = siw.member_id
left join report_doc_tags rdt 
    on ser.report_id = rdt.report_id
    )
;


  