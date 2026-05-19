
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_referral
  
  copy grants
  
  
  as (
    select 
    message_id,
    id as referral_pk_id, 
    type, 
    priority, 
    reason, 
    insurance_provider, 
    insurance_group_number, 
    insurance_authorization_number,
    is_time_pending,
    requested_date, 
    provider,
    location,
    on_behalf_of_provider,
    referral_id,
    created_at,
    updated_at
from source_prod.leadingreach.referral
  );

