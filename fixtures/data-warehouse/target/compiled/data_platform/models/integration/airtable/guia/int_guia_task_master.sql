select
	suvida_id,
	email_to as source_key,
	signed_datetime as request_date,
	referral_body_text as requestor_notes,
	referral_id as task_id,
	md5(cast(coalesce(cast(referral_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as task_master_integration_skey,
from dw_dev.dev_jkizer.patient_referral
where email_to in ('guia_APS@suvidahealthcare.com','guia_medicaid@suvidahealthcare.com','guia_prescriptions@suvidahealthcare.com','guia_AD@suvidahealthcare.com','qualitystars@suvidahealthcare.com','guia_homevisit@suvidahealthcare.com','guia_TOChomevisit@suvidahealthcare.com','guia_sdoh@suvidahealthcare.com','guia_other@suvidahealthcare.com') -- matches source key in Airtable config
and creation_date >= '2026-03-25' -- placeholder for dev work
-- probably need to decide how to handle deletions