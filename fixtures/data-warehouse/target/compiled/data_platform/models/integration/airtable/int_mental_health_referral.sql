

with clinical_values as (
	select
		suvida_id,
		/* PHQ9 */
		max(iff(history_type = 'PHQ-9' and patient_history_index = 1, history_value_numeric, null)) as most_recent_phq_9_value,
		max(iff(history_type = 'PHQ-9' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_phq_9_date,
		max(iff(history_type = 'PHQ-9' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_phq_9_value,
		max(iff(history_type = 'PHQ-9' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_phq_9_date,
		/* PHQ2 */
		max(iff(history_type = 'PHQ-2' and patient_history_index = 1, history_value_numeric, null)) as most_recent_phq_2_value,
		max(iff(history_type = 'PHQ-2' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_phq_2_date,
		max(iff(history_type = 'PHQ-2' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_phq_2_value,
		max(iff(history_type = 'PHQ-2' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_phq_2_date,
		/* GAD7 */
		max(iff(history_type = 'GAD-7' and patient_history_index = 1, history_value_numeric, null)) as most_recent_gad_7_value,
		max(iff(history_type = 'GAD-7' and patient_history_index = 1, date(creation_datetime), null)) as most_recent_gad_7_date,
		max(iff(history_type = 'GAD-7' and patient_history_index = 2, history_value_numeric, null)) as second_most_recent_gad_7_value,
		max(iff(history_type = 'GAD-7' and patient_history_index = 2, date(creation_datetime), null)) as second_most_recent_gad_7_date,
	from dw_dev.dev_jkizer.fct_patient_history
	where history_type in ('GAD-7', 'PHQ-9', 'PHQ-2') and history_value_numeric is not null
	group by all
),

-- One-time MH Airtable migration snapshot: tags active as of 2026-04-19.
-- Going forward, new MH patients flow in via referrals only; do not change this date.
mh_tags as (
	select
		suvida_id,
		patient_tag_skey,
		tag_value,
		creation_datetime as tag_creation_datetime,
		deletion_datetime as tag_deletion_datetime,
		tag_created_by_user_id,
	from dw_dev.dev_jkizer.fct_patient_tag
	where tag_value in ('MH-T', 'MH-Palabras Sanadoras', 'MH-GG WAITLIST')
		and creation_datetime < '2026-04-19'
		and (deletion_datetime is null or deletion_datetime >= '2026-04-19')
),

referral_rows as (
	select
		/* Source */
		'Referral'::varchar as source_type,
		/* Identifiers */
		pr.suvida_id,
		pr.elation_id,
		/* Patient Summary Data */
		ps.full_name,
		ps.birth_date,
		ps.phone,
		ps.phone_type,
		ps.secondary_phone,
		ps.secondary_phone_type,
		ps.elation_patient_url,
		ps.location_name,
		ps.elation_location_name,
		ps.provider_name,
		ps.elation_provider_name,
		ps.last_pcp_appt_date,
		ps.next_pcp_appt_date,
		ps.next_mh_appt_date,
		ps.next_careteam_appt_date,
		ps.census_rolling_12_ip_admit,
		ps.census_rolling_3_ip_admit,
		ps.is_active_assignment,
		ps.active_tag_list,
		ps.payer_name,
		ps.payer_member_id,
		ps.fap_completion_date,
		ps.is_fap_enrolled,
		ps.next_fap_form_due,
		/* Program Specific Data */
		ps.num_mh_visits_ytd,
		ps.first_mh_appt_date,
		ps.last_mh_appt_date,
		ps.mh_appt_completion_rate_rolling_12,
		ps.mh_appt_no_show_rate_rolling_12,
		ps.mh_appt_cancelled_rate_rolling_12,
		/* Referral Info */
		to_varchar(pr.referral_id) as referral_id,
		pr.referral_body_text,
		pr.email_to,
		pr.processing_status,
		pr.resolution_state,
		pr.clinical_reason,
		pr.recipient_first_name,
		pr.recipient_last_name,
		pr.recipient_org_name,
		pr.recipient_specialty,
		pr.referral_date,
		pr.document_date,
		pr.creation_date,
		pr.signed_date,
		pr.signed_datetime,
		pr.referral_icd_list,
		pr.referral_icd_description_list,
		pr.created_by_user_name,
		pr.sent_by_user_name,
		pr.signed_by_username,
		/* Tag Info (null for referral rows) */
		null::varchar as tag_value,
		null::timestamp as tag_creation_datetime,
		null::timestamp as tag_deletion_datetime,
		null::varchar as tag_created_by_user_id,
		/* clinical values */
		cv.most_recent_phq_9_value,
		cv.most_recent_phq_9_date,
		cv.second_most_recent_phq_9_value,
		cv.second_most_recent_phq_9_date,
		cv.most_recent_phq_2_value,
		cv.most_recent_phq_2_date,
		cv.second_most_recent_phq_2_value,
		cv.second_most_recent_phq_2_date,
		cv.most_recent_gad_7_value,
		cv.most_recent_gad_7_date,
		cv.second_most_recent_gad_7_value,
		cv.second_most_recent_gad_7_date,
		/* Airtable Sync Driver Fields -- keep identical to main so existing Airtable records aren't recreated */
		md5(cast(coalesce(cast(referral_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_unique_key,
		md5(cast(coalesce(cast(pr.signed_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.signed_by_username as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.referral_icd_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.mh_appt_completion_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_mh_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_mh_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.first_mh_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pr.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_12_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_3_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.fap_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_fap_enrolled as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_fap_form_due as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.secondary_phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_9_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_9_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_9_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_9_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_2_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_2_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_2_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_2_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_gad_7_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_gad_7_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_gad_7_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_gad_7_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey,
	from dw_dev.dev_jkizer.patient_referral pr
	left join dw_dev.dev_jkizer.patient_summary ps
		using (suvida_id)
	left join clinical_values cv
		using (suvida_id)
	where pr.is_deleted = false -- will not include deleted referrals
		and email_to = 'mentalhealth@suvidahealthcare.com' -- use this to control which referrals we pick up
		and creation_date >= '2026-01-01'
),

tag_rows as (
	select
		/* Source */
		'Elation Tag'::varchar as source_type,
		/* Identifiers */
		t.suvida_id,
		ps.elation_id,
		/* Patient Summary Data */
		ps.full_name,
		ps.birth_date,
		ps.phone,
		ps.phone_type,
		ps.secondary_phone,
		ps.secondary_phone_type,
		ps.elation_patient_url,
		ps.location_name,
		ps.elation_location_name,
		ps.provider_name,
		ps.elation_provider_name,
		ps.last_pcp_appt_date,
		ps.next_pcp_appt_date,
		ps.next_mh_appt_date,
		ps.next_careteam_appt_date,
		ps.census_rolling_12_ip_admit,
		ps.census_rolling_3_ip_admit,
		ps.is_active_assignment,
		ps.active_tag_list,
		ps.payer_name,
		ps.payer_member_id,
		ps.fap_completion_date,
		ps.is_fap_enrolled,
		ps.next_fap_form_due,
		/* Program Specific Data */
		ps.num_mh_visits_ytd,
		ps.first_mh_appt_date,
		ps.last_mh_appt_date,
		ps.mh_appt_completion_rate_rolling_12,
		ps.mh_appt_no_show_rate_rolling_12,
		ps.mh_appt_cancelled_rate_rolling_12,
		/* Referral Info (null for tag rows) */
		null::varchar as referral_id,
		null::varchar as referral_body_text,
		null::varchar as email_to,
		null::varchar as processing_status,
		null::varchar as resolution_state,
		null::varchar as clinical_reason,
		null::varchar as recipient_first_name,
		null::varchar as recipient_last_name,
		null::varchar as recipient_org_name,
		null::varchar as recipient_specialty,
		null::date as referral_date,
		null::date as document_date,
		null::date as creation_date,
		null::date as signed_date,
		null::timestamp as signed_datetime,
		null::varchar as referral_icd_list,
		null::varchar as referral_icd_description_list,
		null::varchar as created_by_user_name,
		null::varchar as sent_by_user_name,
		null::varchar as signed_by_username,
		/* Tag Info */
		t.tag_value,
		t.tag_creation_datetime,
		t.tag_deletion_datetime,
		t.tag_created_by_user_id,
		/* clinical values */
		cv.most_recent_phq_9_value,
		cv.most_recent_phq_9_date,
		cv.second_most_recent_phq_9_value,
		cv.second_most_recent_phq_9_date,
		cv.most_recent_phq_2_value,
		cv.most_recent_phq_2_date,
		cv.second_most_recent_phq_2_value,
		cv.second_most_recent_phq_2_date,
		cv.most_recent_gad_7_value,
		cv.most_recent_gad_7_date,
		cv.second_most_recent_gad_7_value,
		cv.second_most_recent_gad_7_date,
		/* Airtable Sync Driver Fields */
		md5(cast(coalesce(cast('Elation Tag' as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.patient_tag_skey as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_unique_key,
		md5(cast(coalesce(cast('Elation Tag' as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(null as date) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(null as varchar) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(null as varchar) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.mh_appt_completion_rate_rolling_12 as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_mh_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.last_mh_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.first_mh_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_patient_url as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.elation_location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_12_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.census_rolling_3_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.fap_completion_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.is_fap_enrolled as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.next_fap_form_due as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ps.secondary_phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_creation_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_deletion_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(t.tag_created_by_user_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_9_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_9_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_9_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_9_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_2_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_phq_2_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_2_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_phq_2_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_gad_7_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.most_recent_gad_7_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_gad_7_value as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cv.second_most_recent_gad_7_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey,
	from mh_tags t
	left join dw_dev.dev_jkizer.patient_summary ps
		using (suvida_id)
	left join clinical_values cv
		using (suvida_id)
)

select * from referral_rows
union all
select * from tag_rows