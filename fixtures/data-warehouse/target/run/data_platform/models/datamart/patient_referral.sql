
  
    

create or replace transient table dw_dev.dev_jkizer.patient_referral
    copy grants
    
    
    as (select 
	suv_ref.*,
	suv_ref.document_date as referral_date,
	eu.user_name as created_by_user_name,
	eu2.user_name as sent_by_user_name,
	eu3.user_name as signed_by_username,
	eu3.user_email as signed_by_email,
	eu3.provider_type as signed_by_provider_type,
	eu3.location_name,
	CASE 
    	WHEN LOWER(suv_ref.recipient_org_name) LIKE 'leading%' 
         	OR LOWER(suv_ref.recipient_first_name) LIKE 'leading%'
    	THEN 1 
    	ELSE 0 
	END AS is_external_referral
from dw_dev.dev_jkizer.fct_referral suv_ref
left join dw_dev.dev_jkizer.dim_ehr_user eu -- created by user info
	on suv_ref.created_by_user_id = eu.user_id
left join dw_dev.dev_jkizer.dim_ehr_user eu2 -- "sent" user info; can be different
	on suv_ref.sender_user_id = eu2.user_id
left join dw_dev.dev_jkizer.dim_provider eu3 -- signed by user info
	on suv_ref.signed_by_user_id = eu3.user_id
where suv_ref.suvida_id is not null 
and is_deleted = false
    )
;


  