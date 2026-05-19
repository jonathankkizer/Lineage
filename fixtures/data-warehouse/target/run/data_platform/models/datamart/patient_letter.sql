
  
    

create or replace transient table dw_dev.dev_jkizer.patient_letter
    copy grants
    
    
    as (select
	md5(cast(coalesce(cast(provider_letter_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_letter_skey,
	siw.suvida_id,
	subject,
	body,
	email_to,
	delivery_method,
	delivery_date,
	recipient_first_name,
	recipient_last_name,
	recipient_middle_name,
	recipient_npi,
	recipient_credentials,
	recipient_contact_type,
	recipient_address,
	recipient_city,
	recipient_state,
	recipient_zip,
	recipient_fax,
	recipient_org_name,
	recipient_specialty,
	document_datetime,
	last_modified_datetime,
	creation_time as creation_datetime,
	deletion_datetime,
	iff(deletion_datetime is null, 0, 1) as is_deleted,
	signed_datetime,
	signed_by_user_id,
	deu.user_name as signed_by_username,
	deu.user_email as signed_by_email,
from dw_dev.dev_jkizer.int_elation_provider_letter pl
inner join dw_dev.dev_jkizer.suvida_id_walk siw
	on pl.patient_id = siw.member_id
	and siw.source = 'Elation'
left join dw_dev.dev_jkizer.dim_ehr_user deu
	on pl.signed_by_user_id = deu.user_id
    )
;


  