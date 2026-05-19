select distinct
   coalesce(idw.suvida_id, simew.suvida_id) as suvida_id,
   szf.customer_elation_id,
   szf.response_id,
   szf.form_id,
   szf.form_name,
   szf.user_id,
   szf.user_email,
   szf.sent_at_datetime,
   szf.completed_at_datetime,
   szf.question_id,
   szf.stand_question as question,
   szf.stand_answer as answer,
   iff(lower(szf.form_name) like '%consent to treatment%', 1, 0) as consent_to_treatment_form_ind,
   iff(lower(szf.form_name) like '%vaccine consent form%', 1, 0) as consent_to_vaccine_form_ind,
   iff(lower(szf.form_name) like '%physical therapy consent%', 1, 0) as consent_to_physical_therapy_form_ind,
   iff(lower(szf.form_name) like '%patient procedure consent%', 1, 0) as consent_to_patient_procedure_form_ind,
   iff(lower(szf.form_name) like '%informed consent for telemedicine medical services (az)%', 1, 0) as consent_to_telemedicine_az_form_ind,
   iff(lower(szf.form_name) like '%informed consent for telemedicine medical services (tx)%', 1, 0) as consent_to_telemedicine_tx_form_ind,
   iff(lower(szf.form_name) like '%event participation consent%', 1, 0) as consent_to_event_participation_form_ind,
   iff(lower(szf.form_name) like '%electronic and text communication consent form%', 1, 0) as consent_to_electronic_text_communication_form_ind,
   iff(lower(szf.form_name) like '%consent for third party involvement%', 1, 0) as consent_to_third_party_involvement_form_ind,
   iff(lower(szf.form_name) like '%consent for documentation assistance%', 1, 0) as consent_to_documentation_assistance_form_ind,
   iff(lower(szf.form_name) like '%authorization to receive protected health information%', 1, 0) as consent_to_receive_phi_form_ind,
   rank() over(partition by idw.suvida_id, szf.stand_question order by szf.completed_at_datetime desc) as rnk 
from dw_dev.dev_jkizer_staging.stg_zentake_form szf 
left join dw_dev.dev_jkizer.suvida_id_walk idw
   on idw.member_id = szf.customer_elation_id
   and idw.source = 'Elation'
left join dw_dev.dev_jkizer.suvida_id_master_elation_walk simew
   on szf.customer_elation_id = simew.elation_id
   and simew.source = 'Elation'
where szf.is_deleted = 0
and szf.customer_elation_id is not null