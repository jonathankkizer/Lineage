
  create or replace   view dw_dev.dev_jkizer_staging.stg_attestation_event_log
  
  copy grants
  
  
  as (
    with base as (
	select
		attestation_opportunity_skey,
		attestation_opportunity_version_skey,
		suvida_id,
		elation_id,
		icd_10_code,
		caregap_id,
		definition_id,
		action,
		date_actioned,
	from source_prod.attestation.attestation_event_log
)
select
	*,
	row_number() over (partition by attestation_opportunity_skey order by date_actioned desc) as attestation_process_event_index, -- 1 = most recent action
from base
  );

