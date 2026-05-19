
  create or replace   view dw_dev.dev_jkizer_staging.stg_attestation_action_event_log
  
  copy grants
  
  
  as (
    /* log of actions taken based on events in Elation UI */
with base as (
	select
		elation_id,
		physician_id,
		visit_note_id,
		icd_10_code,
		doc_tag as doctag,
		date_actioned
	from source_prod.attestation.attestation_action_event_log
), skey_creation as (
	select
		md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(coalesce(to_varchar(year(vn.document_date)), to_varchar(year(b.date_actioned))) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(b.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as attestation_opportunity_skey, -- reconstruct attestation_opportunity_skey; coalescing dates to handle case if visit note id is not yet available
		suvida_id,
		elation_id,
		icd_10_code,
		coalesce(to_varchar(year(vn.document_date)), to_varchar(year(b.date_actioned))) as measure_year,
		doctag,
		date_actioned,
	from base b
	left join dw_dev.dev_jkizer.suvida_id_walk siw
		on b.elation_id = siw.member_id
		and siw.source = 'Elation'
	left join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn
		on b.visit_note_id = vn.visit_note_id
)
select
	*,
	case
		when doctag ilike 'confirm%' then 'accept'
		when doctag ilike 'disconfirm%' then 'deny'
		else null
	end as action_event_type,
	row_number() over (partition by attestation_opportunity_skey order by date_actioned desc) as attestation_event_index, -- 1 = most recent action per skey
from skey_creation
  );

