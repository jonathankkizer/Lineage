

with text_cleanup as (
	select
		*,
		/* Below are EXAMPLES and would need polish */
		icd_10_code || ' - ' || code_description as gap_title,
		array_to_string(array_construct_compact(coder_info, redoc_info, payer_suspect_info), ' | ') as gap_short_text, -- order: redoc, coder, payer suspect
		array_to_string(array_construct_compact(mapped_hccs), ' | ') as long_text,
	from dw_dev.dev_jkizer.attestation_opportunity
	where measure_year = year(current_date())
), uat_filter_criteria as (
	select suvida_id, elation_id, num_pcp_visits_ytd
	from dw_dev.dev_jkizer.patient_summary ps
), version_skey as (
	select
		tc.*,
		ufc.elation_id,
		md5(cast(coalesce(cast(attestation_opportunity_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(gap_title as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(gap_short_text as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(long_text as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as attestation_opportunity_version_skey,
	from text_cleanup tc
	inner join uat_filter_criteria ufc
		on tc.suvida_id = ufc.suvida_id
)
select
	vs.*,
	ael.caregap_id,
	case
		when ael.attestation_opportunity_skey is not null and ael.action != 'Close' and vs.attestation_opportunity_status = 'closed' then 'close'
		when ael.attestation_opportunity_skey is null and vs.attestation_opportunity_status = 'open' then 'create'
		when ael.attestation_opportunity_skey is not null and vs.attestation_opportunity_status = 'open' and ael.action = 'Close' then 'create'
		when vs.attestation_opportunity_version_skey != ael.attestation_opportunity_version_skey and ael.action != 'Close' then 'update'
		else null
	end as attestation_event_needed_action,
from version_skey vs
left join dw_dev.dev_jkizer_staging.stg_attestation_event_log ael
	on vs.attestation_opportunity_skey = ael.attestation_opportunity_skey
	and ael.attestation_process_event_index = 1